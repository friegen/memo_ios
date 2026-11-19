import Foundation
import Observation

/// メモタブの状態。
struct MemoListUiState: Equatable {
    var isLoading = true
    var memos: [MemoSummary] = []
    var sort = MemoSort()

    /// 読み込みが終わって1件もないときだけ「メモがありません」を出す。
    var showEmpty: Bool { !isLoading && memos.isEmpty }
}

/// メモタブの一回きりのイベント。
enum MemoListEvent: Equatable, Sendable {
    /// ゴミ箱に移したことを知らせ、「元に戻す」を出す。
    case showMovedToTrash(memoId: Int64)
}

/// メモタブ（メモ一覧）の ViewModel（Android 版の MemoListViewModel にあたる）。
@Observable
final class MemoListViewModel {
    private(set) var uiState = MemoListUiState()

    private let observeMemoTabMemos: ObserveMemoTabMemosUseCase
    private let setMemoTabSort: SetMemoTabSortUseCase
    private let moveMemoToTrash: MoveMemoToTrashUseCase
    private let restoreMemo: RestoreMemoUseCase
    private let setMemoPinned: SetMemoPinnedUseCase
    @ObservationIgnored private let eventChannel = EventChannel<MemoListEvent>()

    init(
        observeMemoTabMemos: ObserveMemoTabMemosUseCase,
        setMemoTabSort: SetMemoTabSortUseCase,
        moveMemoToTrash: MoveMemoToTrashUseCase,
        restoreMemo: RestoreMemoUseCase,
        setMemoPinned: SetMemoPinnedUseCase
    ) {
        self.observeMemoTabMemos = observeMemoTabMemos
        self.setMemoTabSort = setMemoTabSort
        self.moveMemoToTrash = moveMemoToTrash
        self.restoreMemo = restoreMemo
        self.setMemoPinned = setMemoPinned
    }

    /// 一回きりのイベント（View の `.task` で受け取る）。
    func events() -> AsyncStream<MemoListEvent> { eventChannel.stream() }

    /// メモと並び順を監視する（画面が出ている間。View の `.task` から呼ぶ）。
    func observe() async {
        do {
            for try await sorted in observeMemoTabMemos() {
                uiState = MemoListUiState(isLoading: false, memos: sorted.memos, sort: sorted.sort)
            }
        } catch {
            AppLog.error("メモタブの読み込みに失敗: \(error)")
        }
    }

    func onSortSelected(_ sort: MemoSort) {
        setMemoTabSort(sort)
    }

    func onDeleteClick(_ memo: MemoSummary) async {
        do {
            try await moveMemoToTrash(memoId: memo.id)
            eventChannel.send(.showMovedToTrash(memoId: memo.id))
        } catch {
            AppLog.error("メモをゴミ箱に移せなかった: \(error)")
        }
    }

    func onUndoDelete(memoId: Int64) async {
        do {
            try await restoreMemo(memoId: memoId)
        } catch {
            AppLog.error("メモを元に戻せなかった: \(error)")
        }
    }

    /// ピン留めの付け外し（一覧の一番上に移るので、お知らせは出さない）。
    func onSetPinned(_ memo: MemoSummary, pinned: Bool) async {
        do {
            try await setMemoPinned(memoId: memo.id, pinned: pinned)
        } catch {
            AppLog.error("ピン留めを変えられなかった: \(error)")
        }
    }
}
