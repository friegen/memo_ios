import SwiftUI

/// メモタブ（メモ一覧）。フォルダに入っていないメモだけを表示する（Android 版の MemoListFragment にあたる）。
struct MemoListScreen: View {
    @Binding var path: NavigationPath
    @State private var viewModel: MemoListViewModel
    @State private var isPasscodeAlertShown = false
    @Bindable private var messageCenter: MessageCenter
    private let authenticator: DeviceAuthenticator

    init(container: AppContainer, path: Binding<NavigationPath>) {
        _path = path
        _viewModel = State(initialValue: container.makeMemoListViewModel())
        messageCenter = container.messageCenter
        authenticator = container.deviceAuthenticator
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
        .passcodeRequiredAlert(isPresented: $isPasscodeAlertShown)
        .undoBanner($messageCenter.item)
        .task { await viewModel.observe() }
        .task {
            for await event in viewModel.events() { handle(event) }
        }
    }

    /// 長押しメニュー: ピン留め／ロック／削除。
    @ViewBuilder
    private func menu(for memo: MemoSummary) -> some View {
        Button {
            Task { await viewModel.onSetPinned(memo, pinned: !memo.isPinned) }
        } label: {
            Label(memo.isPinned ? LocalizedStringKey("action_unpin") : "action_pin", systemImage: memo.isPinned ? "pin.slash" : "pin")
        }
        LockMenuButton(isLocked: memo.isLocked) {
            changeLock(currentlyLocked: memo.isLocked) { await viewModel.onSetLocked(memo, locked: $0) }
        }
        Button(role: .destructive) {
            Task { await viewModel.onDeleteClick(memo) }
        } label: {
            Label("action_delete", systemImage: "trash")
        }
    }

    /// 長押しメニューの「ロックする／ロックを外す」。外すときは認証、ロックするときはパスコードがあるか確かめてから。
    private func changeLock(currentlyLocked: Bool, apply: @escaping (Bool) async -> Void) {
        Task {
            switch await authenticator.confirmLockChange(currentlyLocked: currentlyLocked) {
            case .apply(let locked): await apply(locked)
            case .cancelled: break
            case .passcodeRequired: isPasscodeAlertShown = true
            }
        }
    }

    private func handle(_ event: MemoListEvent) {
        switch event {
        case .showMovedToTrash(let memoId):
            messageCenter.show(L10n.string("memo_moved_to_trash")) {
                Task { await viewModel.onUndoDelete(memoId: memoId) }
            }
        case .showLockChanged(let locked):
            messageCenter.show(L10n.string(locked ? "lock_done" : "unlock_done"))
        }
    }
}
