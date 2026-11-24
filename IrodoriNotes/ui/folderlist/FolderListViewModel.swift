import Foundation
import Observation

/// フォルダタブの状態。
struct FolderListUiState: Equatable {
    var isLoading = true
    var folders: [Folder] = []
    var sort = FolderSort()

    /// 読み込みが終わって1件もないときだけ「フォルダがありません」を出す。
    var showEmpty: Bool { !isLoading && folders.isEmpty }
}

/// フォルダタブの一回きりのイベント。
enum FolderListEvent: Equatable, Sendable {
    /// フォルダの中を開く（作成直後）。
    case openFolder(folderId: Int64)
    /// 中身があるフォルダの削除を確認する。
    case confirmDelete(folder: Folder, contents: FolderContents)
    /// ゴミ箱に移したことを知らせ、「元に戻す」を出す。
    case showMovedToTrash(folderId: Int64)
    /// ロックを付けた／外したことを知らせる。
    case showLockChanged(locked: Bool)
}

/// フォルダタブ（フォルダタブ直下のフォルダ一覧）の ViewModel（Android 版の FolderListViewModel にあたる）。
@Observable
final class FolderListViewModel {
    private(set) var uiState = FolderListUiState()

    private let observeRootFolders: ObserveRootFoldersUseCase
    private let setFolderListSort: SetFolderListSortUseCase
    private let createFolder: CreateFolderUseCase
    private let updateFolder: UpdateFolderUseCase
    private let countFolderContents: CountFolderContentsUseCase
    private let moveFolderToTrash: MoveFolderToTrashUseCase
    private let restoreFolder: RestoreFolderUseCase
    private let setFolderPinned: SetFolderPinnedUseCase
    private let setFolderLocked: SetFolderLockedUseCase
    @ObservationIgnored private let eventChannel = EventChannel<FolderListEvent>()

    init(
        observeRootFolders: ObserveRootFoldersUseCase,
        setFolderListSort: SetFolderListSortUseCase,
        createFolder: CreateFolderUseCase,
        updateFolder: UpdateFolderUseCase,
        countFolderContents: CountFolderContentsUseCase,
        moveFolderToTrash: MoveFolderToTrashUseCase,
        restoreFolder: RestoreFolderUseCase,
        setFolderPinned: SetFolderPinnedUseCase,
        setFolderLocked: SetFolderLockedUseCase
    ) {
        self.observeRootFolders = observeRootFolders
        self.setFolderListSort = setFolderListSort
        self.createFolder = createFolder
        self.updateFolder = updateFolder
        self.countFolderContents = countFolderContents
        self.moveFolderToTrash = moveFolderToTrash
        self.restoreFolder = restoreFolder
        self.setFolderPinned = setFolderPinned
        self.setFolderLocked = setFolderLocked
    }

    func events() -> AsyncStream<FolderListEvent> { eventChannel.stream() }

    /// フォルダと並び順を監視する（画面が出ている間）。
    func observe() async {
        do {
            for try await sorted in observeRootFolders() {
                uiState = FolderListUiState(isLoading: false, folders: sorted.folders, sort: sorted.sort)
            }
        } catch {
            AppLog.error("フォルダタブの読み込みに失敗: \(error)")
        }
    }

    func onSortSelected(_ sort: FolderSort) {
        setFolderListSort(sort)
    }

    /// 作成のシートで決定したとき。作ったフォルダの中を開く。
    func onCreateFolder(name: String, color: FolderColor) async {
        do {
            let id = try await createFolder(parentId: nil, name: name, color: color)
            eventChannel.send(.openFolder(folderId: id))
        } catch {
            AppLog.error("フォルダを作れなかった: \(error)")
        }
    }

    /// 編集のシートで決定したとき（更新日は変えない）。
    func onUpdateFolder(_ folder: Folder, name: String, color: FolderColor) async {
        do {
            try await updateFolder(folderId: folder.id, name: name, color: color)
        } catch {
            AppLog.error("フォルダを変えられなかった: \(error)")
        }
    }

    /// 長押しメニューの「削除」。中身があれば件数を出して確認し、空ならそのままゴミ箱へ移す
    /// （空のフォルダはメモと同じく、確認なしで削除して「元に戻す」を出す）。
    func onDeleteClick(_ folder: Folder) async {
        do {
            let contents = try await countFolderContents(folderId: folder.id)
            if contents.folderCount == 0 && contents.memoCount == 0 {
                await moveToTrash(folder.id)
            } else {
                eventChannel.send(.confirmDelete(folder: folder, contents: contents))
            }
        } catch {
            AppLog.error("フォルダの中身を数えられなかった: \(error)")
        }
    }

    /// 確認ダイアログで削除を選んだとき。
    func onDeleteConfirmed(_ folder: Folder) async {
        await moveToTrash(folder.id)
    }

    func onUndoDelete(folderId: Int64) async {
        do {
            try await restoreFolder(folderId: folderId)
        } catch {
            AppLog.error("フォルダを元に戻せなかった: \(error)")
        }
    }

    /// ピン留めの付け外し（一覧の一番上に移るので、お知らせは出さない）。
    func onSetPinned(_ folder: Folder, pinned: Bool) async {
        do {
            try await setFolderPinned(folderId: folder.id, pinned: pinned)
        } catch {
            AppLog.error("ピン留めを変えられなかった: \(error)")
        }
    }

    /// ロックの付け外し（外すときの認証・ロックするときのパスコードの確認は画面側で済ませてから呼ぶ）。
    func onSetLocked(_ folder: Folder, locked: Bool) async {
        do {
            try await setFolderLocked(folderId: folder.id, locked: locked)
            eventChannel.send(.showLockChanged(locked: locked))
        } catch {
            AppLog.error("ロックを変えられなかった: \(error)")
        }
    }

    private func moveToTrash(_ folderId: Int64) async {
        do {
            try await moveFolderToTrash(folderId: folderId)
            eventChannel.send(.showMovedToTrash(folderId: folderId))
        } catch {
            AppLog.error("フォルダをゴミ箱に移せなかった: \(error)")
        }
    }
}
