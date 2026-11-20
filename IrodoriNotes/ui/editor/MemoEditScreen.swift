import SwiftUI

/// メモの編集画面（Android 版の MemoEditActivity にあたる）。下タブは隠す（Android 版では別の Activity で、下タブがない）。
///
/// - ナビゲーションバー: 戻る・文字数（タイトル）・行数または選んだ範囲の文字数（サブタイトル）・キーボードを閉じる
/// - 開いたときからあるメモを空にして戻るときは確認ダイアログ（このときは左端からのスワイプで戻らず、ダイアログを出す）
struct MemoEditScreen: View {
    @State private var viewModel: MemoEditViewModel
    @State private var controller = MemoEditorController()
    @State private var isKeyboardVisible = false
    @State private var isEmptyDialogShown = false
    @Bindable private var messageCenter: MessageCenter
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    init(container: AppContainer, memoId: Int64?, folderId: Int64?) {
        _viewModel = State(initialValue: container.makeMemoEditViewModel(memoId: memoId, folderId: folderId))
        messageCenter = container.messageCenter
    }

    var body: some View {
        let state = viewModel.uiState
        let confirmsOnLeave = viewModel.shouldConfirmDeleteOnLeave
        MemoTextView(
            controller: controller,
            settings: state.editorSettings,
            onTextChange: { viewModel.onContentChanged($0) },
            onSelectionChange: { viewModel.onSelectionChanged(selectedText: $0) },
            onLimitReached: {
                messageCenter.show(L10n.format("editor_limit_reached", MemoPolicy.maxChars.formatted()))
            })
            .overlay(alignment: .topLeading) {
                if state.isEmpty {
                    Text("editor_hint")
                        .font(.system(size: state.editorSettings.fontSize.sizePt))
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 17) // 入力欄の余白（12）＋文字の左の余白（5）
                        .padding(.vertical, 12)
                        .allowsHitTesting(false)
                }
            }
            .toolbar(.hidden, for: .tabBar)
            .modifier(EditorHeader(title: headerTitle(state), subtitle: headerSubtitle(state)))
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
            }
            .onDisappear {
                // 画面を閉じたときに保存する（ここで作ったメモを空にして閉じたときは破棄する）
                viewModel.onLeave(isClosing: true)
            }
            .task { await viewModel.load() }
            .task { await viewModel.observeSettings() }
            .task {
                for await event in viewModel.events() { handle(event) }
            }
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
            controller.setText(MemoHtml.toPlainText(html)) // TODO(ステップ5): 装飾付きで入れる
            if isNewMemo { controller.focus() }
        case .notFound:
            messageCenter.show(L10n.string("editor_not_found"))
            dismiss()
        }
    }
}

/// ナビゲーションバーの中央のタイトルとサブタイトル。
/// iOS 26 からは標準のサブタイトル（`.navigationSubtitle`）を使う（iOS 26.0 では自前の中央の表示 `.principal` が出ないため）。
/// iOS 18〜25 は自前で2行に並べる。
private struct EditorHeader: ViewModifier {
    let title: String
    let subtitle: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title).font(.headline)
                            Text(subtitle).font(.caption).foregroundStyle(.secondary)
                        }
                        .lineLimit(1)
                    }
                }
        }
    }
}
