import Foundation
import Observation

/// フォルダの中の状態。
struct FolderDetailUiState: Equatable {
    var isLoading = true
    /// 開いているフォルダ。ゴミ箱に入った・存在しない場合は nil
    var folder: Folder?
    /// 上の階層（フォルダタブ直下から親まで）。ナビゲーションバーのサブタイトルに使う。1階層目なら空
    var ancestors: [FolderPathEntry] = []
    var folders: [Folder] = []
    var memos: [MemoSummary] = []
    var folderSort = FolderSort()
    var memoSort = MemoSort()

    /// この中にフォルダを作れるか（最大の階層ではもう作れない）。
    var canCreateFolder: Bool { ancestors.count + 1 < FolderPolicy.maxDepth }

    /// 中身を見せる前に認証が要るフォルダ（ロックしている上の階層と、このフォルダ）。空なら認証は要らない
    var lockedFolderIds: [Int64] {
        ancestors.filter(\.isLocked).map(\.id) + (folder?.isLocked == true ? [folder!.id] : [])
    }

    /// 読み込みが終わって中身が空のときだけ「このフォルダは空です」を出す。
    var showEmpty: Bool { !isLoading && folders.isEmpty && memos.isEmpty }
}

/// フォルダの中の一回きりのイベント。
enum FolderDetailEvent: Equatable, Sendable {
    case openFolder(folderId: Int64)
    case confirmDeleteFolder(folder: Folder, contents: FolderContents)
    case showMemoMovedToTrash(memoId: Int64)
    case showFolderMovedToTrash(folderId: Int64)
    /// メモの移動先を選ばせる。階層が分かるよう全フォルダを渡し、今いるフォルダは選べないようにする
    case chooseMoveTarget(memo: MemoSummary, targets: [FolderTreeEntry])
    /// 移動できるフォルダが1つもない
    case showNoMoveTargets
    case showMemoMoved(targetName: String)
    /// 開いているフォルダが無くなった（ゴミ箱に入ったなど）。前の画面に戻る
    case close
    /// フォルダの作成のシートを出す
    case showCreateFolderSheet
    /// ロックを付けた／外したことを知らせる。
    case showLockChanged(locked: Bool)
}

/// フォルダの中（フォルダを上、メモを下に並べる）の ViewModel（Android 版の FolderDetailViewModel にあたる）。
/// フォルダの中のフォルダを開くときも同じ画面を積む。
@Observable
final class FolderDetailViewModel {
    let folderId: Int64
    private(set) var uiState = FolderDetailUiState()

    private let observeFolder: ObserveFolderUseCase
    private let observeChildFolders: ObserveChildFoldersUseCase
    private let observeFolderMemos: ObserveFolderMemosUseCase
    private let getFolderPath: GetFolderPathUseCase
    private let getFolderTree: GetFolderTreeUseCase
    private let setFolderListSort: SetFolderListSortUseCase
    private let setFolderMemoSort: SetFolderMemoSortUseCase
    private let createFolder: CreateFolderUseCase
    private let updateFolder: UpdateFolderUseCase
    private let countFolderContents: CountFolderContentsUseCase
    private let moveFolderToTrash: MoveFolderToTrashUseCase
    private let restoreFolder: RestoreFolderUseCase
    private let moveMemoToTrash: MoveMemoToTrashUseCase
    private let restoreMemo: RestoreMemoUseCase
    private let moveMemoToFolder: MoveMemoToFolderUseCase
    private let setMemoPinned: SetMemoPinnedUseCase
    private let setFolderPinned: SetFolderPinnedUseCase
    private let setMemoLocked: SetMemoLockedUseCase
    private let setFolderLocked: SetFolderLockedUseCase
    @ObservationIgnored private let eventChannel = EventChannel<FolderDetailEvent>()
    @ObservationIgnored private var hasClosed = false

    init(
        folderId: Int64,
        observeFolder: ObserveFolderUseCase,
        observeChildFolders: ObserveChildFoldersUseCase,
        observeFolderMemos: ObserveFolderMemosUseCase,
        getFolderPath: GetFolderPathUseCase,
        getFolderTree: GetFolderTreeUseCase,
        setFolderListSort: SetFolderListSortUseCase,
        setFolderMemoSort: SetFolderMemoSortUseCase,
        createFolder: CreateFolderUseCase,
        updateFolder: UpdateFolderUseCase,
        countFolderContents: CountFolderContentsUseCase,
        moveFolderToTrash: MoveFolderToTrashUseCase,
        restoreFolder: RestoreFolderUseCase,
        moveMemoToTrash: MoveMemoToTrashUseCase,
        restoreMemo: RestoreMemoUseCase,
        moveMemoToFolder: MoveMemoToFolderUseCase,
        setMemoPinned: SetMemoPinnedUseCase,
        setFolderPinned: SetFolderPinnedUseCase,
        setMemoLocked: SetMemoLockedUseCase,
        setFolderLocked: SetFolderLockedUseCase
    ) {
        self.folderId = folderId
        self.observeFolder = observeFolder
        self.observeChildFolders = observeChildFolders
        self.observeFolderMemos = observeFolderMemos
        self.getFolderPath = getFolderPath
        self.getFolderTree = getFolderTree
        self.setFolderListSort = setFolderListSort
        self.setFolderMemoSort = setFolderMemoSort
        self.createFolder = createFolder
        self.updateFolder = updateFolder
        self.countFolderContents = countFolderContents
        self.moveFolderToTrash = moveFolderToTrash
        self.restoreFolder = restoreFolder
        self.moveMemoToTrash = moveMemoToTrash
        self.restoreMemo = restoreMemo
        self.moveMemoToFolder = moveMemoToFolder
        self.setMemoPinned = setMemoPinned
        self.setFolderPinned = setFolderPinned
        self.setMemoLocked = setMemoLocked
        self.setFolderLocked = setFolderLocked
    }

    func events() -> AsyncStream<FolderDetailEvent> { eventChannel.stream() }

    /// フォルダ・上の階層・中のフォルダ・中のメモを監視する（画面が出ている間）。3つとも1回届いたら読み込み終わり。
    func observe() async {
        var loaded: Set<Int> = []
        func markLoaded(_ part: Int) {
            loaded.insert(part)
            if loaded.count == 3 { uiState.isLoading = false }
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { @MainActor [self] in
                do {
                    for try await folder in observeFolder(folderId: folderId) {
                        guard let folder else {
                            close()
                            continue
                        }
                        // フォルダが変わるたびに上の階層も取り直す（上の階層の名前の変更などに合わせるため）
                        let path = try await getFolderPath(folderId: folderId)
                        uiState.folder = folder
                        uiState.ancestors = Array(path.dropLast())
                        markLoaded(0)
                    }
                } catch {
                    AppLog.error("フォルダを読めなかった: \(error)")
                }
            }
            group.addTask { @MainActor [self] in
                do {
                    for try await sorted in observeChildFolders(parentId: folderId) {
                        uiState.folders = sorted.folders
                        uiState.folderSort = sorted.sort
                        markLoaded(1)
                    }
                } catch {
                    AppLog.error("中のフォルダを読めなかった: \(error)")
                }
            }
            group.addTask { @MainActor [self] in
                do {
                    for try await sorted in observeFolderMemos(folderId: folderId) {
                        uiState.memos = sorted.memos
                        uiState.memoSort = sorted.sort
                        markLoaded(2)
                    }
                } catch {
                    AppLog.error("中のメモを読めなかった: \(error)")
                }
            }
        }
    }

    private func close() {
        guard !hasClosed else { return }
        hasClosed = true
        eventChannel.send(.close)
    }

    // MARK: 作る

    /// ＋の「新しいフォルダ」。最大の階層では作れない。
    /// TODO(ステップ11): フォルダの中にフォルダを作るにはリワード広告が必要（Android 版「広告」）
    func onAddFolderClick() {
        guard uiState.canCreateFolder else { return }
        eventChannel.send(.showCreateFolderSheet)
    }

    /// 作成のシートで決定したとき。作ったフォルダの中を開く。
    func onCreateFolder(name: String, color: FolderColor) async {
        guard uiState.canCreateFolder else { return }
        do {
            let id = try await createFolder(parentId: folderId, name: name, color: color)
            eventChannel.send(.openFolder(folderId: id))
        } catch {
            AppLog.error("フォルダを作れなかった: \(error)")
        }
    }

    // MARK: 並び替え

    func onFolderSortSelected(_ sort: FolderSort) {
        setFolderListSort(sort)
    }

    func onMemoSortSelected(_ sort: MemoSort) {
        setFolderMemoSort(sort)
    }

    // MARK: フォルダの長押し

    func onUpdateFolder(_ folder: Folder, name: String, color: FolderColor) async {
        do {
            try await updateFolder(folderId: folder.id, name: name, color: color)
        } catch {
            AppLog.error("フォルダを変えられなかった: \(error)")
        }
    }

    /// 中身があれば件数を出して確認し、空ならそのままゴミ箱へ移す（フォルダタブと同じ）。
    func onDeleteFolderClick(_ folder: Folder) async {
        do {
            let contents = try await countFolderContents(folderId: folder.id)
            if contents.folderCount == 0 && contents.memoCount == 0 {
                await trashFolder(folder.id)
            } else {
                eventChannel.send(.confirmDeleteFolder(folder: folder, contents: contents))
            }
        } catch {
            AppLog.error("フォルダの中身を数えられなかった: \(error)")
        }
    }

    func onDeleteFolderConfirmed(_ folder: Folder) async {
        await trashFolder(folder.id)
    }

    private func trashFolder(_ id: Int64) async {
        do {
            try await moveFolderToTrash(folderId: id)
            eventChannel.send(.showFolderMovedToTrash(folderId: id))
        } catch {
            AppLog.error("フォルダをゴミ箱に移せなかった: \(error)")
        }
    }

    func onUndoDeleteFolder(folderId: Int64) async {
        do {
            try await restoreFolder(folderId: folderId)
        } catch {
            AppLog.error("フォルダを元に戻せなかった: \(error)")
        }
    }

    func onSetFolderPinned(_ folder: Folder, pinned: Bool) async {
        do {
            try await setFolderPinned(folderId: folder.id, pinned: pinned)
        } catch {
            AppLog.error("ピン留めを変えられなかった: \(error)")
        }
    }

    // MARK: メモの長押し

    func onDeleteMemoClick(_ memo: MemoSummary) async {
        do {
            try await moveMemoToTrash(memoId: memo.id)
            eventChannel.send(.showMemoMovedToTrash(memoId: memo.id))
        } catch {
            AppLog.error("メモをゴミ箱に移せなかった: \(error)")
        }
    }

    func onUndoDeleteMemo(memoId: Int64) async {
        do {
            try await restoreMemo(memoId: memoId)
        } catch {
            AppLog.error("メモを元に戻せなかった: \(error)")
        }
    }

    /// メモのロックの付け外し（外すときの認証・ロックするときのパスコードの確認は画面側で済ませてから呼ぶ）。
    func onSetMemoLocked(_ memo: MemoSummary, locked: Bool) async {
        do {
            try await setMemoLocked(memoId: memo.id, locked: locked)
            eventChannel.send(.showLockChanged(locked: locked))
        } catch {
            AppLog.error("ロックを変えられなかった: \(error)")
        }
    }

    /// 中のフォルダのロックの付け外し。
    func onSetFolderLocked(_ folder: Folder, locked: Bool) async {
        do {
            try await setFolderLocked(folderId: folder.id, locked: locked)
            eventChannel.send(.showLockChanged(locked: locked))
        } catch {
            AppLog.error("ロックを変えられなかった: \(error)")
        }
    }

    func onSetMemoPinned(_ memo: MemoSummary, pinned: Bool) async {
        do {
            try await setMemoPinned(memoId: memo.id, pinned: pinned)
        } catch {
            AppLog.error("ピン留めを変えられなかった: \(error)")
        }
    }

    /// 「別のフォルダへ移動」。このフォルダ以外のすべてのフォルダが移動先の候補（一覧には今いるフォルダも選べない形で出す）。
    func onMoveMemoClick(_ memo: MemoSummary) async {
        do {
            let tree = try await getFolderTree()
            if tree.contains(where: { $0.id != folderId }) {
                eventChannel.send(.chooseMoveTarget(memo: memo, targets: tree))
            } else {
                eventChannel.send(.showNoMoveTargets)
            }
        } catch {
            AppLog.error("移動先を読めなかった: \(error)")
        }
    }

    func onMoveTargetSelected(_ memo: MemoSummary, target: FolderTreeEntry) async {
        guard target.id != folderId else { return }
        do {
            try await moveMemoToFolder(memoId: memo.id, targetFolderId: target.id)
            eventChannel.send(.showMemoMoved(targetName: target.name))
        } catch {
            AppLog.error("メモを移動できなかった: \(error)")
        }
    }
}
