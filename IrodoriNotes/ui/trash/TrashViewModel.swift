import Foundation
import Observation

/// ゴミ箱の状態。
struct TrashUiState: Equatable {
    var isLoading = true
    var items: [TrashItem] = []

    /// 読み込みが終わって1件もないときだけ「ゴミ箱は空です」を出す。
    var showEmpty: Bool { !isLoading && items.isEmpty }

    /// 「ゴミ箱を空にする」を押せるか。
    var canEmpty: Bool { !items.isEmpty }
}

/// ゴミ箱の一回きりのイベント。
enum TrashEvent: Equatable, Sendable {
    /// 上の階層のフォルダもゴミ箱にあるので、「フォルダごと復元しますか？」と確認する。
    case confirmRestoreWithFolder(TrashItem)
    /// 元の場所に戻したことを知らせる。
    case showRestored
    /// メモの完全削除を確認する。
    case confirmDeleteMemo(TrashedMemo)
    /// フォルダの完全削除を、一緒に消える中身の数とともに確認する。
    case confirmDeleteFolder(TrashedFolder, FolderContents)
    /// 完全に削除したことを知らせる。
    case showDeleted
    /// 「ゴミ箱を空にする」を確認する。
    case confirmEmptyTrash
    /// ゴミ箱を空にしたことを知らせる。
    case showEmptied
}

/// ゴミ箱（Android 版の TrashViewModel にあたる）。復元・完全削除・空にする。
///
/// 決まり（Android 版 requirements.md「削除とゴミ箱」）:
/// - 上の階層のフォルダもゴミ箱にあるものを復元するときは、確認してから上の階層ごと戻す
/// - 完全削除・空にするは元に戻せないので、必ず確認する
@Observable
final class TrashViewModel {
    private(set) var uiState = TrashUiState()

    private let observeTrashItems: ObserveTrashItemsUseCase
    private let restoreMemo: RestoreMemoUseCase
    private let restoreFolder: RestoreFolderUseCase
    private let deleteMemoPermanently: DeleteMemoPermanentlyUseCase
    private let deleteFolderPermanently: DeleteFolderPermanentlyUseCase
    private let countTrashedFolderContents: CountTrashedFolderContentsUseCase
    private let emptyTrash: EmptyTrashUseCase
    @ObservationIgnored private let eventChannel = EventChannel<TrashEvent>()

    init(
        observeTrashItems: ObserveTrashItemsUseCase,
        restoreMemo: RestoreMemoUseCase,
        restoreFolder: RestoreFolderUseCase,
        deleteMemoPermanently: DeleteMemoPermanentlyUseCase,
        deleteFolderPermanently: DeleteFolderPermanentlyUseCase,
        countTrashedFolderContents: CountTrashedFolderContentsUseCase,
        emptyTrash: EmptyTrashUseCase
    ) {
        self.observeTrashItems = observeTrashItems
        self.restoreMemo = restoreMemo
        self.restoreFolder = restoreFolder
        self.deleteMemoPermanently = deleteMemoPermanently
        self.deleteFolderPermanently = deleteFolderPermanently
        self.countTrashedFolderContents = countTrashedFolderContents
        self.emptyTrash = emptyTrash
    }

    func events() -> AsyncStream<TrashEvent> { eventChannel.stream() }

    /// ゴミ箱の中身を監視する（画面が出ている間）。
    func observe() async {
        do {
            for try await items in observeTrashItems() {
                uiState = TrashUiState(isLoading: false, items: items)
            }
        } catch {
            AppLog.error("ゴミ箱の読み込みに失敗: \(error)")
        }
    }

    /// メニューの「元に戻す」。上の階層もゴミ箱にあるときは先に確認する。
    func onRestoreClick(_ item: TrashItem) async {
        if item.isParentInTrash {
            eventChannel.send(.confirmRestoreWithFolder(item))
        } else {
            await onRestoreConfirmed(item)
        }
    }

    /// 復元する（上の階層がゴミ箱にあれば、それも一緒に戻る）。
    func onRestoreConfirmed(_ item: TrashItem) async {
        do {
            switch item {
            case .memo(let memo): try await restoreMemo(memoId: memo.memo.id)
            case .folder(let folder): try await restoreFolder(folderId: folder.folder.id)
            }
            eventChannel.send(.showRestored)
        } catch {
            AppLog.error("ゴミ箱から戻せなかった: \(error)")
        }
    }

    /// メニューの「完全に削除」。フォルダは一緒に消える中身の数を数えてから確認する。
    func onDeletePermanentlyClick(_ item: TrashItem) async {
        switch item {
        case .memo(let memo):
            eventChannel.send(.confirmDeleteMemo(memo))
        case .folder(let folder):
            do {
                eventChannel.send(.confirmDeleteFolder(folder, try await countTrashedFolderContents(folderId: folder.folder.id)))
            } catch {
                AppLog.error("ゴミ箱のフォルダの中身を数えられなかった: \(error)")
            }
        }
    }

    func onDeleteMemoConfirmed(memoId: Int64) async {
        do {
            try await deleteMemoPermanently(memoId: memoId)
            eventChannel.send(.showDeleted)
        } catch {
            AppLog.error("メモを完全に削除できなかった: \(error)")
        }
    }

    func onDeleteFolderConfirmed(folderId: Int64) async {
        do {
            try await deleteFolderPermanently(folderId: folderId)
            eventChannel.send(.showDeleted)
        } catch {
            AppLog.error("フォルダを完全に削除できなかった: \(error)")
        }
    }

    /// ナビゲーションバーの「ゴミ箱を空にする」。空のときは何もしない。
    func onEmptyTrashClick() {
        guard uiState.canEmpty else { return }
        eventChannel.send(.confirmEmptyTrash)
    }

    func onEmptyTrashConfirmed() async {
        do {
            try await emptyTrash()
            eventChannel.send(.showEmptied)
        } catch {
            AppLog.error("ゴミ箱を空にできなかった: \(error)")
        }
    }
}
