import SwiftUI

/// フォルダタブ（フォルダタブ直下のフォルダ一覧。Android 版の FolderListFragment にあたる）。
struct FolderListScreen: View {
    @Binding var path: NavigationPath
    @State private var viewModel: FolderListViewModel
    @State private var sheet: FolderSheet.Mode?
    /// シートが画面に出ている（閉じる途中も含む）。閉じ終わるまで次の画面を開かない
    @State private var isSheetOnScreen = false
    /// シートが閉じ終わったら開くフォルダ（作成したフォルダ）
    @State private var pendingOpenFolderId: Int64?
    @State private var deleteRequest: (folder: Folder, contents: FolderContents)?
    @Bindable private var messageCenter: MessageCenter

    init(container: AppContainer, path: Binding<NavigationPath>) {
        _path = path
        _viewModel = State(initialValue: container.makeFolderListViewModel())
        messageCenter = container.messageCenter
    }

    var body: some View {
        List {
            ForEach(viewModel.uiState.folders) { folder in
                Button {
                    path.append(AppRoute.folder(folderId: folder.id))
                } label: {
                    FolderRow(folder: folder)
                }
                .listRowBackground(folder.color.rowBackground)
                .accessibilityIdentifier("folder_row")
                .contextMenu { menu(for: folder) }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.uiState.showEmpty {
                Text("folder_list_empty")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                    .accessibilityIdentifier("folder_list_empty")
            }
        }
        .navigationTitle("tab_folder")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                SortMenu(options: folderSortOptions, current: viewModel.uiState.sort) { viewModel.onSortSelected($0) }
                Button {
                    showSheet(.create)
                } label: {
                    Label("action_add", systemImage: "plus")
                }
                .accessibilityIdentifier("add_button")
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
        .alert(
            "folder_delete_title",
            isPresented: Binding(get: { deleteRequest != nil }, set: { if !$0 { deleteRequest = nil } }),
            presenting: deleteRequest
        ) { request in
            Button("action_delete", role: .destructive) {
                Task { await viewModel.onDeleteConfirmed(request.folder) }
            }
            Button("action_cancel", role: .cancel) {}
        } message: { request in
            Text(L10n.format("folder_delete_message", request.folder.name, folderContentsText(request.contents)))
        }
        .undoBanner($messageCenter.item)
        .task { await viewModel.observe() }
        .task {
            for await event in viewModel.events() { handle(event) }
        }
    }

    /// 長押しメニュー: ピン留め／名前・色の変更／削除（ロックはステップ9で足す）。
    @ViewBuilder
    private func menu(for folder: Folder) -> some View {
        Button {
            Task { await viewModel.onSetPinned(folder, pinned: !folder.isPinned) }
        } label: {
            Label(folder.isPinned ? LocalizedStringKey("action_unpin") : "action_pin",
                  systemImage: folder.isPinned ? "pin.slash" : "pin")
        }
        Button {
            showSheet(.edit(folder))
        } label: {
            Label("action_edit_folder", systemImage: "pencil")
        }
        Button(role: .destructive) {
            Task { await viewModel.onDeleteClick(folder) }
        } label: {
            Label("action_delete", systemImage: "trash")
        }
    }

    private func showSheet(_ mode: FolderSheet.Mode) {
        isSheetOnScreen = true
        sheet = mode
    }

    private func handle(_ event: FolderListEvent) {
        switch event {
        case .openFolder(let folderId):
            if isSheetOnScreen {
                pendingOpenFolderId = folderId
            } else {
                path.append(AppRoute.folder(folderId: folderId))
            }
        case .confirmDelete(let folder, let contents):
            deleteRequest = (folder, contents)
        case .showMovedToTrash(let folderId):
            messageCenter.show(L10n.string("folder_moved_to_trash")) {
                Task { await viewModel.onUndoDelete(folderId: folderId) }
            }
        }
    }
}
