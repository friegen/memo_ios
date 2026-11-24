import SwiftUI

/// メモの編集画面（Android 版の MemoEditActivity にあたる）。下タブは隠す（Android 版では別の Activity で、下タブがない）。
///
/// - ナビゲーションバー: 戻る・文字数（タイトル）・行数または選んだ範囲の文字数（サブタイトル）・キーボードを閉じる
/// - 開いたときからあるメモを空にして戻るときは確認ダイアログ（このときは左端からのスワイプで戻らず、ダイアログを出す）
/// - ロックしたメモ（ロックしたフォルダの中のメモも）は、認証するまで本文を隠す（`applyLock`）
struct MemoEditScreen: View {
    @State private var viewModel: MemoEditViewModel
    @State private var controller = MemoEditorController()
    @State private var isKeyboardVisible = false
    @State private var isEmptyDialogShown = false
    @State private var isFormatPanelOpen = false
    @State private var formatPanelState = FormatPanelState()
    /// 認証した時点の `LockSession.generation`。同じなら認証済み（アプリから離れると generation が変わり、もう一度聞く）
    @State private var unlockedGeneration: Int?
    @State private var isUnlockPromptShowing = false
    @State private var isPasscodeAlertShown = false
    @State private var holdsProtectedScreen = false
    @Bindable private var messageCenter: MessageCenter
    private let lockSession: LockSession
    private let authenticator: DeviceAuthenticator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer, memoId: Int64?, folderId: Int64?) {
        _viewModel = State(initialValue: container.makeMemoEditViewModel(memoId: memoId, folderId: folderId))
        messageCenter = container.messageCenter
        lockSession = container.lockSession
        authenticator = container.deviceAuthenticator
    }

    var body: some View {
        let state = viewModel.uiState
        let confirmsOnLeave = viewModel.shouldConfirmDeleteOnLeave
        let isHidden = !state.isLoading && !isUnlocked(state)
        MemoTextView(
            controller: controller,
            settings: state.editorSettings,
            onTextChange: { viewModel.onContentChanged($0) },
            onSelectionChange: { viewModel.onSelectionChanged(selectedText: $0) },
            onLimitReached: {
                messageCenter.show(L10n.format("editor_limit_reached", MemoPolicy.maxChars.formatted()))
            })
            // 認証するまで本文を隠す（入力欄は残したまま見えなくする）
            .opacity(isHidden ? 0 : 1)
            .allowsHitTesting(!isHidden)
            .accessibilityHidden(isHidden)
            .overlay {
                if isHidden { LockedPlaceholder(message: "memo_locked_placeholder") }
            }
            .overlay(alignment: .topLeading) {
                if state.isEmpty && !isHidden {
                    Text("editor_hint")
                        .font(.system(size: state.editorSettings.fontSize.sizePt))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 17) // 入力欄の余白（12）＋文字の左の余白（5）
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .safeAreaInset(edge: .bottom) {
                // 書式パネル: 画面の下（キーボードが出ているときはキーボードのすぐ上）。選択を外しても閉じない
                if isFormatPanelOpen {
                    FormatPanel(
                        state: formatPanelState,
                        onToggle: { controller.toggle($0) },
                        onColor: { controller.setColor($0) },
                        onClose: { setFormatPanelOpen(false) })
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .titleAndSubtitle(headerTitle(state), subtitle: headerSubtitle(state))
            .navigationBarBackButtonHidden(confirmsOnLeave)
            .toolbar {
                if confirmsOnLeave {
                    // 空にしたメモは、戻る前に確認する（標準の戻るボタンの代わり）
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            isEmptyDialogShown = true
                        } label: {
                            Label("action_back", systemImage: "chevron.backward")
                        }
                        .accessibilityIdentifier("editor_back_button")
                    }
                }
                if isKeyboardVisible {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            controller.hideKeyboard()
                        } label: {
                            Label("action_hide_keyboard", systemImage: "keyboard.chevron.compact.down")
                        }
                        .accessibilityIdentifier("hide_keyboard_button")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    // 書式ボタン（オン／オフ）。書式パネルを開閉する（Android 版 v1.9）
                    Toggle(isOn: Binding(get: { isFormatPanelOpen }, set: { setFormatPanelOpen($0) })) {
                        Label("action_format", systemImage: "textformat")
                    }
                    .toggleStyle(.button)
                    .disabled(isHidden)
                    .accessibilityIdentifier("format_button")
                }
            }
            // 左端からのスワイプで戻ろうとしたとき（確認が要るときは標準のスワイプが効かないので、ここで確認を出す）
            .simultaneousGesture(
                DragGesture(minimumDistance: 30).onEnded { value in
                    if confirmsOnLeave, value.startLocation.x < 24, value.translation.width > 80 {
                        isEmptyDialogShown = true
                    }
                })
            .alert("editor_empty_title", isPresented: $isEmptyDialogShown) {
                Button("action_delete", role: .destructive) {
                    viewModel.onDeleteConfirmed()
                    messageCenter.show(L10n.string("memo_moved_to_trash"))
                    dismiss()
                }
                Button("editor_empty_revert_and_close") {
                    viewModel.onRevertAndClose()
                    dismiss()
                }
                Button("editor_empty_keep_editing", role: .cancel) {}
            } message: {
                Text("editor_empty_message")
            }
            .passcodeRequiredAlert(isPresented: $isPasscodeAlertShown) { dismiss() }
            .undoBanner($messageCenter.item)
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillShowNotification)) { _ in
                isKeyboardVisible = true
            }
            .onReceive(NotificationCenter.default.publisher(for: UIResponder.keyboardWillHideNotification)) { _ in
                isKeyboardVisible = false
            }
            .onChange(of: scenePhase) { _, phase in
                // アプリが裏に回るときに保存する（Android の onPause）
                if phase != .active { viewModel.onLeave(isClosing: false) }
                applyLock()
            }
            .onChange(of: state.isLoading) { applyLock() }
            // アプリから離れてロックし直されたら、すぐに本文を隠す（戻ってきたときに認証する）
            .onChange(of: lockSession.generation) { applyLock() }
            .onDisappear {
                // 画面を閉じたときに保存する（ここで作ったメモを空にして閉じたときは破棄する）
                viewModel.onLeave(isClosing: true)
                if holdsProtectedScreen {
                    lockSession.releaseProtectedScreen()
                    holdsProtectedScreen = false
                }
            }
            .onAppear {
                controller.onFormatPanelStateChange = { formatPanelState = $0 }
            }
            .task { await viewModel.load() }
            .task { await viewModel.observeSettings() }
            .task {
                for await event in viewModel.events() { handle(event) }
            }
    }

    // MARK: ロック（docs/requirements.md「ロック」）

    /// 本文を見せてよいか（守る必要がない・この状態で認証済み・ロックしたフォルダの中から開いた）。
    private func isUnlocked(_ state: MemoEditUiState) -> Bool {
        if !state.isProtected { return true }
        if unlockedGeneration == lockSession.generation { return true }
        // フォルダのロックだけなら、フォルダに入るときに認証していれば聞かない（メモ自体のロックは開くたびに聞く）
        if !state.isLocked { return lockSession.areUnlocked(state.lockedFolderIds) }
        return false
    }

    /// ロックしたメモは、認証するまで本文を隠す（画面が前に出ているときに認証の画面を出す）。
    /// 守る必要があるメモを開いている間は、アプリの切り替え画面に中身を映さない。認証しなかったら閉じる。
    private func applyLock() {
        let state = viewModel.uiState
        guard !state.isLoading else { return }
        if state.isProtected && !holdsProtectedScreen {
            lockSession.acquireProtectedScreen()
            holdsProtectedScreen = true
        }
        guard !isUnlocked(state) else { return }
        controller.hideKeyboard()
        if isFormatPanelOpen { setFormatPanelOpen(false) }
        guard scenePhase == .active, !isUnlockPromptShowing else { return }
        isUnlockPromptShowing = true
        Task {
            let result = await authenticator.unlock()
            isUnlockPromptShowing = false
            switch result {
            case .unlocked:
                unlockedGeneration = lockSession.generation
                lockSession.unlockFolders(state.lockedFolderIds)
            case .cancelled:
                dismiss() // 認証しなかったら閉じる
            case .passcodeRequired:
                isPasscodeAlertShown = true // 閉じたら画面も閉じる
            }
        }
    }

    private func setFormatPanelOpen(_ open: Bool) {
        isFormatPanelOpen = open
        controller.setFormatPanelOpen(open)
    }

    /// ナビゲーションバーのタイトル: 文字数。
    private func headerTitle(_ state: MemoEditUiState) -> String {
        state.isLoading ? "" : L10n.count("editor_char_count", state.charCount)
    }

    /// ナビゲーションバーのサブタイトル: 文字を選んでいる間は選んだ範囲の文字数、それ以外は行数。
    private func headerSubtitle(_ state: MemoEditUiState) -> String {
        if state.isLoading { return "" }
        if let selected = state.selectedCharCount { return L10n.count("editor_selected_char_count", selected) }
        return L10n.count("editor_line_count", state.lineCount)
    }

    private func handle(_ event: MemoEditEvent) {
        switch event {
        case .setInitialText(let html, let isNewMemo):
            controller.setHTML(html)
            if isNewMemo { controller.focus() }
        case .notFound:
            messageCenter.show(L10n.string("editor_not_found"))
            dismiss()
        }
    }
}
