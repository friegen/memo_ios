import SwiftUI

/// ゴミ箱（設定から開く。Android 版の TrashFragment にあたる）。
/// - 項目をタップ・長押し → 「元に戻す」「完全に削除」のメニュー
/// - ナビゲーションバーの右 → 「ゴミ箱を空にする」（中身があるときだけ押せる）
/// 完全削除と空にするは元に戻せないので、必ず確認のアラートを出す。
struct TrashScreen: View {
    @State private var viewModel: TrashViewModel
    @State private var confirmation: TrashConfirmation?
    @Bindable private var messageCenter: MessageCenter

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeTrashViewModel())
        messageCenter = container.messageCenter
    }

    var body: some View {
        List {
            Section {
                ForEach(viewModel.uiState.items) { item in
                    // タップでも長押しでもメニューを出す（Android と同じ。iOS のメニューのボタンは長押しでも開く）
                    Menu {
                        menu(for: item)
                    } label: {
                        TrashRow(item: item)
                    }
                    .accessibilityIdentifier("trash_row")
                }
            } header: {
                Text(L10n.count("trash_retention_notice", Int(TrashPolicy.retentionDays)))
                    .textCase(nil)
            }
        }
        .overlay {
            if viewModel.uiState.showEmpty {
                Text("trash_empty")
                    .foregroundStyle(.secondary)
                    .padding()
                    .accessibilityIdentifier("trash_empty")
            }
        }
        .navigationTitle("settings_trash")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.onEmptyTrashClick()
                } label: {
                    Label("action_empty_trash", systemImage: "xmark.bin")
                }
                .disabled(!viewModel.uiState.canEmpty)
                .accessibilityIdentifier("empty_trash_button")
            }
        }
        .alert(
            Text(confirmation?.title ?? ""),
            isPresented: Binding(get: { confirmation != nil }, set: { if !$0 { confirmation = nil } }),
            presenting: confirmation
        ) { confirmation in
            Button(confirmation.confirmLabel, role: confirmation.isDestructive ? .destructive : nil) {
                Task { await confirmation.onConfirm() }
            }
            Button("action_cancel", role: .cancel) {}
        } message: { confirmation in
            Text(confirmation.message)
        }
        .undoBanner($messageCenter.item)
        .task { await viewModel.observe() }
        .task {
            for await event in viewModel.events() { handle(event) }
        }
    }

    /// 項目のメニュー: 元に戻す / 完全に削除。
    @ViewBuilder
    private func menu(for item: TrashItem) -> some View {
        Button {
            Task { await viewModel.onRestoreClick(item) }
        } label: {
            Label("action_restore", systemImage: "arrow.uturn.backward")
        }
        Button(role: .destructive) {
            Task { await viewModel.onDeletePermanentlyClick(item) }
        } label: {
            Label("action_delete_permanently", systemImage: "trash")
        }
    }

    private func handle(_ event: TrashEvent) {
        switch event {
        case .confirmRestoreWithFolder(let item):
            let message = switch item {
            case .memo: L10n.string("trash_restore_memo_with_folder_message")
            case .folder: L10n.string("trash_restore_folder_with_parent_message")
            }
            confirmation = TrashConfirmation(
                title: L10n.string("trash_restore_with_folder_title"), message: message,
                confirmLabel: L10n.string("action_restore"), isDestructive: false
            ) { [viewModel] in await viewModel.onRestoreConfirmed(item) }
        case .confirmDeleteMemo(let memo):
            confirmation = TrashConfirmation(
                title: L10n.string("trash_delete_title"), message: L10n.string("trash_delete_memo_message"),
                confirmLabel: L10n.string("action_delete"), isDestructive: true
            ) { [viewModel] in await viewModel.onDeleteMemoConfirmed(memoId: memo.memo.id) }
        case .confirmDeleteFolder(let folder, let contents):
            let contentsText = folderContentsText(contents)
            let message = contentsText.isEmpty
                ? L10n.format("trash_delete_folder_empty_message", folder.folder.name)
                : L10n.format("trash_delete_folder_message", folder.folder.name, contentsText)
            confirmation = TrashConfirmation(
                title: L10n.string("trash_delete_title"), message: message,
                confirmLabel: L10n.string("action_delete"), isDestructive: true
            ) { [viewModel] in await viewModel.onDeleteFolderConfirmed(folderId: folder.folder.id) }
        case .confirmEmptyTrash:
            confirmation = TrashConfirmation(
                title: L10n.string("trash_empty_title"), message: L10n.string("trash_empty_message"),
                confirmLabel: L10n.string("action_empty"), isDestructive: true
            ) { [viewModel] in await viewModel.onEmptyTrashConfirmed() }
        case .showRestored:
            messageCenter.show(L10n.string("trash_restored"))
        case .showDeleted:
            messageCenter.show(L10n.string("trash_deleted"))
        case .showEmptied:
            messageCenter.show(L10n.string("trash_emptied"))
        }
    }
}

/// ゴミ箱の確認のアラートの中身。
private struct TrashConfirmation {
    let title: String
    let message: String
    let confirmLabel: String
    let isDestructive: Bool
    let onConfirm: () async -> Void
}

/// ゴミ箱の1行: アイコン・（ロック）名前 / 削除日 / 元の場所（フォルダは中身も）/ 上の階層もゴミ箱にあるときの注意。
/// メニューのボタンの中に置くと文字がアクセントの色に塗られるので、文字色は決まった色（.label など）で指定する。
private struct TrashRow: View {
    let item: TrashItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            icon
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    if isLocked {
                        Image(systemName: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(Color(.secondaryLabel))
                            .accessibilityLabel(Text("lock_icon_description"))
                    }
                    Text(title)
                        .font(.body)
                        .foregroundStyle(Color(.label))
                        .lineLimit(1)
                }
                Text(L10n.format("trash_deleted_at", DateTimeText.format(item.deletedAt)))
                    .font(.caption)
                    .foregroundStyle(Color(.secondaryLabel))
                ForEach(details, id: \.self) { line in
                    Text(line)
                        .font(.caption)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                if let note {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(Color.accentColor)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var icon: some View {
        switch item {
        case .memo:
            Image(systemName: "note.text")
                .font(.body)
                .foregroundStyle(Color.accentColor)
                .frame(width: 32, height: 32)
                .accessibilityHidden(true)
        case .folder(let folder):
            ColorBadge(color: folder.folder.color)
        }
    }

    private var isLocked: Bool {
        switch item {
        case .memo(let memo): memo.isLocked
        case .folder(let folder): folder.isLocked
        }
    }

    private var title: String {
        switch item {
        case .memo(let memo): memo.memo.firstLine.isEmpty ? L10n.string("memo_no_text") : memo.memo.firstLine
        case .folder(let folder): folder.folder.name
        }
    }

    /// 元の場所。フォルダは中身も（別の行に）。
    private var details: [String] {
        switch item {
        case .memo(let memo):
            return [location(memo.folderName ?? L10n.string("trash_location_memo_tab"))]
        case .folder(let folder):
            let contents = folderContentsText(FolderContents(folderCount: folder.folderCount, memoCount: folder.memoCount))
            return [
                location(folder.parentName ?? L10n.string("trash_location_folder_tab")),
                contents.isEmpty ? L10n.string("trash_folder_no_contents") : L10n.format("trash_folder_contents", contents),
            ]
        }
    }

    /// 上の階層もゴミ箱にあるときの注意。
    private var note: String? {
        switch item {
        case .memo(let memo): memo.isFolderInTrash ? L10n.string("trash_note_folder_in_trash") : nil
        case .folder(let folder): folder.isParentInTrash ? L10n.string("trash_note_parent_in_trash") : nil
        }
    }

    private func location(_ place: String) -> String {
        L10n.format("trash_location", place)
    }
}
