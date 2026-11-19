import SwiftUI

/// メモタブ（メモ一覧）。フォルダに入っていないメモだけを表示する（Android 版の MemoListFragment にあたる）。
struct MemoListScreen: View {
    @Binding var path: NavigationPath
    @State private var viewModel: MemoListViewModel
    @State private var undoItem: UndoItem?

    init(container: AppContainer, path: Binding<NavigationPath>) {
        _path = path
        _viewModel = State(initialValue: container.makeMemoListViewModel())
    }

    var body: some View {
        List {
            ForEach(viewModel.uiState.memos) { memo in
                Button {
                    path.append(AppRoute.editor(memoId: memo.id, folderId: nil))
                } label: {
                    MemoRow(memo: memo)
                }
                .accessibilityIdentifier("memo_row")
                .contextMenu { menu(for: memo) }
            }
        }
        .listStyle(.plain)
        .overlay {
            if viewModel.uiState.showEmpty {
                Text("memo_list_empty")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding()
                    .accessibilityIdentifier("memo_list_empty")
            }
        }
        .navigationTitle("tab_memo")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                SortMenu(options: memoSortOptions, current: viewModel.uiState.sort) { viewModel.onSortSelected($0) }
                Button {
                    path.append(AppRoute.editor(memoId: nil, folderId: nil))
                } label: {
                    Label("action_add", systemImage: "plus")
                }
                .accessibilityIdentifier("add_button")
            }
        }
        .undoBanner($undoItem)
        .task { await viewModel.observe() }
        .task {
            for await event in viewModel.events() { handle(event) }
        }
    }

    /// 長押しメニュー: ピン留め／削除（ロックはステップ9で足す）。
    @ViewBuilder
    private func menu(for memo: MemoSummary) -> some View {
        Button {
            Task { await viewModel.onSetPinned(memo, pinned: !memo.isPinned) }
        } label: {
            Label(memo.isPinned ? LocalizedStringKey("action_unpin") : "action_pin", systemImage: memo.isPinned ? "pin.slash" : "pin")
        }
        Button(role: .destructive) {
            Task { await viewModel.onDeleteClick(memo) }
        } label: {
            Label("action_delete", systemImage: "trash")
        }
    }

    private func handle(_ event: MemoListEvent) {
        switch event {
        case .showMovedToTrash(let memoId):
            undoItem = UndoItem(message: L10n.string("memo_moved_to_trash")) {
                Task { await viewModel.onUndoDelete(memoId: memoId) }
            }
        }
    }
}
