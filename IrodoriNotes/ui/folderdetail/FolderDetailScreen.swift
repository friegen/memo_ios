import SwiftUI

/// フォルダの中（フォルダを上、メモを下に並べる。Android 版の FolderDetailFragment にあたる）。
///
/// - ナビゲーションバー: 戻る・フォルダ名（2階層目以降はサブタイトルに上の階層「趣味 › 読書」）・並び替え・＋
/// - ＋: 「新しいメモ」「新しいフォルダ」（5階層目ではフォルダを選べない）
/// - 並び替え: 「メモの並び順」「フォルダの並び順」の2つのサブメニュー
/// - 開いているフォルダがゴミ箱に入ったら（別の画面で削除されたなど）、前の画面に戻る
/// - このフォルダか上の階層がロックされていれば、認証するまで中身を隠す（`applyLock`）。認証しなかったら前の画面に戻る
struct FolderDetailScreen: View {
    @Binding var path: NavigationPath
    @State private var viewModel: FolderDetailViewModel
    @State private var sheet: FolderSheet.Mode?
    /// シートが画面に出ている（閉じる途中も含む）。閉じ終わるまで次の画面を開かない
    @State private var isSheetOnScreen = false
    /// シートが閉じ終わったら開くフォルダ（作成したフォルダ）
    @State private var pendingOpenFolderId: Int64?
    @State private var deleteRequest: (folder: Folder, contents: FolderContents)?
    @State private var moveRequest: (memo: MemoSummary, targets: [FolderTreeEntry])?
    @State private var isUnlockPromptShowing = false
    @State private var isPasscodeAlertShown = false
    /// 「パスコードが必要です」を閉じたら前の画面に戻るか（中に入るための認証のとき。ロックの付け外しのときは戻らない）
    @State private var closesAfterPasscodeAlert = false
    @State private var holdsProtectedScreen = false
    /// この画面が出たときの画面の積み重ねの数。閉じたとき（これより減ったとき）にフォルダをロックし直す
    @State private var depthOnScreen: Int?
    @Bindable private var messageCenter: MessageCenter
    private let lockSession: LockSession
    private let authenticator: DeviceAuthenticator
    @Environment(\.dismiss) private var dismiss
    @Environment(\.scenePhase) private var scenePhase

    /// 上の階層の区切り（言語によらず同じ記号。Android の folder_path_separator と同じ）
    private static let pathSeparator = " › "

    init(container: AppContainer, folderId: Int64, path: Binding<NavigationPath>) {
        _path = path
        _viewModel = State(initialValue: container.makeFolderDetailViewModel(folderId: folderId))
        messageCenter = container.messageCenter
        lockSession = container.lockSession
        authenticator = container.deviceAuthenticator
    }

    var body: some View {
        let state = viewModel.uiState
        let isHidden = !state.isLoading && !lockSession.areUnlocked(state.lockedFolderIds)
        List {
            ForEach(state.folders) { folder in
                Button {
                    path.append(AppRoute.folder(folderId: folder.id))
                } label: {
                    FolderRow(folder: folder)
                }
                .listRowBackground(folder.color.rowBackground)
                .accessibilityIdentifier("folder_row")
                .contextMenu { folderMenu(folder) }
            }
            ForEach(state.memos) { memo in
                Button {
                    path.append(AppRoute.editor(memoId: memo.id, folderId: viewModel.folderId))
                } label: {
                    MemoRow(memo: memo)
                }
                .accessibilityIdentifier("memo_row")
                .contextMenu { memoMenu(memo) }
            }
        }
        .listStyle(.plain)
        // 認証するまで中身を隠す
        .opacity(isHidden ? 0 : 1)
        .allowsHitTesting(!isHidden)
        .accessibilityHidden(isHidden)
        .overlay {
            if isHidden {
                LockedPlaceholder(message: "folder_locked_placeholder")
            } else if state.showEmpty {
                Text("folder_detail_empty")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                    .accessibilityIdentifier("folder_detail_empty")
            }
        }
        .titleAndSubtitle(state.folder?.name ?? "", subtitle: state.ancestors.map(\.name).joined(separator: Self.pathSeparator))
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                sortMenu(state)
                addMenu(state)
            }
        }

        .sheet(item: $sheet, onDismiss: {
            // シートが閉じる途中で次の画面を開くと、開いた画面の読み込み（.task）が動かないことがあるので、閉じ終わってから開く
            isSheetOnScreen = false
            if let folderId = pendingOpenFolderId {
                pendingOpenFolderId = nil
                path.append(AppRoute.folder(folderId: folderId))
            }
        }) { mode in
            FolderSheet(mode: mode) { name, color in
                switch mode {
                case .create: Task { await viewModel.onCreateFolder(name: name, color: color) }
                case .edit(let folder): Task { await viewModel.onUpdateFolder(folder, name: name, color: color) }
                }
            }
        }
        .sheet(isPresented: Binding(get: { moveRequest != nil }, set: { if !$0 { moveRequest = nil } })) {
            if let request = moveRequest {
                MoveTargetSheet(targets: request.targets, currentFolderId: viewModel.folderId) { target in
                    Task { await viewModel.onMoveTargetSelected(request.memo, target: target) }
                }
            }
        }
        .alert(
            "folder_delete_title",
            isPresented: Binding(get: { deleteRequest != nil }, set: { if !$0 { deleteRequest = nil } }),
            presenting: deleteRequest
        ) { request in
            Button("action_delete", role: .destructive) {
                Task { await viewModel.onDeleteFolderConfirmed(request.folder) }
            }
            Button("action_cancel", role: .cancel) {}
        } message: { request in
            Text(L10n.format("folder_delete_message", request.folder.name, folderContentsText(request.contents)))
        }
        .passcodeRequiredAlert(isPresented: $isPasscodeAlertShown) {
            if closesAfterPasscodeAlert { dismiss() }
        }
        .undoBanner($messageCenter.item)
        .onAppear {
            if depthOnScreen == nil { depthOnScreen = path.count }
            applyLock()
        }
        .onDisappear {
            // このフォルダの画面を閉じた（上の階層に戻った・タブを切り替えた）ら、またロックする。中の画面を開いただけならロックしない
            if let depth = depthOnScreen, path.count < depth { lockSession.lockFolder(viewModel.folderId) }
            if holdsProtectedScreen {
                lockSession.releaseProtectedScreen()
                holdsProtectedScreen = false
            }
        }
        .onChange(of: state.isLoading) { applyLock() }
        .onChange(of: state.lockedFolderIds) { applyLock() }
        // アプリから離れてロックし直されたら、すぐに中身を隠す（戻ってきたときに認証する）
        .onChange(of: lockSession.generation) { applyLock() }
        .onChange(of: scenePhase) { applyLock() }
        .task { await viewModel.observe() }
        .task {
            for await event in viewModel.events() { handle(event) }
        }
    }

    /// 並び替え: 「メモの並び順」「フォルダの並び順」を選んでから、それぞれの並び順（1つのメニューに14個並ぶと選びにくいため。Android と同じ）。
    private func sortMenu(_ state: FolderDetailUiState) -> some View {
        Menu {
            Menu {
                SortOptionsSection(options: memoSortOptions, current: state.memoSort) { viewModel.onMemoSortSelected($0) }
            } label: {
                Label("sort_target_memos", systemImage: "note.text")
            }
            Menu {
                SortOptionsSection(options: folderSortOptions, current: state.folderSort) { viewModel.onFolderSortSelected($0) }
            } label: {
                Label("sort_target_folders", systemImage: "folder")
            }
        } label: {
            Label("action_sort", systemImage: "arrow.up.arrow.down")
        }
        .disabled(isHidden(state))
        .accessibilityIdentifier("sort_button")
    }

    /// ＋: 新しいメモ／新しいフォルダ（5階層目ではフォルダを押せない。なぜ作れないか気づけるよう、メニューには出す）。
    private func addMenu(_ state: FolderDetailUiState) -> some View {
        Menu {
            Button {
                path.append(AppRoute.editor(memoId: nil, folderId: viewModel.folderId))
            } label: {
                Label("add_memo", systemImage: "note.text.badge.plus")
            }
            Button {
                viewModel.onAddFolderClick()
            } label: {
                Label("add_folder", systemImage: "folder.badge.plus")
            }
            .disabled(!state.canCreateFolder)
        } label: {
            Label("action_add", systemImage: "plus")
        }
        .disabled(isHidden(state))
        .accessibilityIdentifier("add_button")
    }

    /// 認証するまで中身を隠しているか。
    private func isHidden(_ state: FolderDetailUiState) -> Bool {
        !state.isLoading && !lockSession.areUnlocked(state.lockedFolderIds)
    }

    // MARK: ロック（docs/requirements.md「ロック」）

    /// このフォルダか上の階層がロックされていれば、認証するまで中身を隠す（画面が前に出ているときに認証の画面を出す）。
    /// その間とロックを外して中身を見せている間は、アプリの切り替え画面に中身を映さない。認証しなかったら前の画面に戻る。
    private func applyLock() {
        let state = viewModel.uiState
        guard !state.isLoading else { return }
        let required = state.lockedFolderIds
        if !required.isEmpty && !holdsProtectedScreen {
            lockSession.acquireProtectedScreen()
            holdsProtectedScreen = true
        }
        guard !lockSession.areUnlocked(required), scenePhase == .active, !isUnlockPromptShowing else { return }
        isUnlockPromptShowing = true
        Task {
            let result = await authenticator.unlock()
            isUnlockPromptShowing = false
            switch result {
            case .unlocked:
                lockSession.unlockFolders(required)
            case .cancelled:
                dismiss() // 認証しなかったら入らない
            case .passcodeRequired:
                closesAfterPasscodeAlert = true
                isPasscodeAlertShown = true
            }
        }
    }

    /// 長押しメニューの「ロックする／ロックを外す」。外すときは認証、ロックするときはパスコードがあるか確かめてから。
    private func changeLock(currentlyLocked: Bool, apply: @escaping (Bool) async -> Void) {
        Task {
            switch await authenticator.confirmLockChange(currentlyLocked: currentlyLocked) {
            case .apply(let locked):
                await apply(locked)
            case .cancelled:
                break
            case .passcodeRequired:
                closesAfterPasscodeAlert = false
                isPasscodeAlertShown = true
            }
        }
    }

    /// フォルダの長押し: ピン留め／ロック／名前・色の変更／削除。
    @ViewBuilder
    private func folderMenu(_ folder: Folder) -> some View {
        Button {
            Task { await viewModel.onSetFolderPinned(folder, pinned: !folder.isPinned) }
        } label: {
            Label(folder.isPinned ? LocalizedStringKey("action_unpin") : "action_pin",
                  systemImage: folder.isPinned ? "pin.slash" : "pin")
        }
        LockMenuButton(isLocked: folder.isLocked) {
            changeLock(currentlyLocked: folder.isLocked) { await viewModel.onSetFolderLocked(folder, locked: $0) }
        }
        Button {
            showSheet(.edit(folder))
        } label: {
            Label("action_edit_folder", systemImage: "pencil")
        }
        Button(role: .destructive) {
            Task { await viewModel.onDeleteFolderClick(folder) }
        } label: {
            Label("action_delete", systemImage: "trash")
        }
    }

    /// メモの長押し: ピン留め／ロック／別のフォルダへ移動／削除。
    @ViewBuilder
    private func memoMenu(_ memo: MemoSummary) -> some View {
        Button {
            Task { await viewModel.onSetMemoPinned(memo, pinned: !memo.isPinned) }
        } label: {
            Label(memo.isPinned ? LocalizedStringKey("action_unpin") : "action_pin",
                  systemImage: memo.isPinned ? "pin.slash" : "pin")
        }
        LockMenuButton(isLocked: memo.isLocked) {
            changeLock(currentlyLocked: memo.isLocked) { await viewModel.onSetMemoLocked(memo, locked: $0) }
        }
        Button {
            Task { await viewModel.onMoveMemoClick(memo) }
        } label: {
            Label("action_move", systemImage: "folder")
        }
        Button(role: .destructive) {
            Task { await viewModel.onDeleteMemoClick(memo) }
        } label: {
            Label("action_delete", systemImage: "trash")
        }
    }

    private func showSheet(_ mode: FolderSheet.Mode) {
        isSheetOnScreen = true
        sheet = mode
    }

    private func handle(_ event: FolderDetailEvent) {
        switch event {
        case .openFolder(let folderId):
            if isSheetOnScreen {
                pendingOpenFolderId = folderId
            } else {
                path.append(AppRoute.folder(folderId: folderId))
            }
        case .confirmDeleteFolder(let folder, let contents):
            deleteRequest = (folder, contents)
        case .showMemoMovedToTrash(let memoId):
            messageCenter.show(L10n.string("memo_moved_to_trash")) {
                Task { await viewModel.onUndoDeleteMemo(memoId: memoId) }
            }
        case .showFolderMovedToTrash(let folderId):
            messageCenter.show(L10n.string("folder_moved_to_trash")) {
                Task { await viewModel.onUndoDeleteFolder(folderId: folderId) }
            }
        case .chooseMoveTarget(let memo, let targets):
            moveRequest = (memo, targets)
        case .showNoMoveTargets:
            messageCenter.show(L10n.string("move_no_targets"))
        case .showMemoMoved(let targetName):
            messageCenter.show(L10n.format("memo_moved_to_folder", targetName))
        case .close:
            dismiss()
        case .showCreateFolderSheet:
            showSheet(.create)
        case .showLockChanged(let locked):
            messageCenter.show(L10n.string(locked ? "lock_done" : "unlock_done"))
        }
    }
}
