import Foundation
import Testing
@testable import IrodoriNotes

/// メモタブの ViewModel（Android 版の MemoListViewModelTest にあたる）。
struct MemoListViewModelTests {
    let container: AppContainer
    let viewModel: MemoListViewModel
    let observeTask: Task<Void, Never>

    init() throws {
        container = try makeTestContainer(now: 1_000).container
        viewModel = container.makeMemoListViewModel()
        let viewModel = viewModel
        observeTask = Task { await viewModel.observe() }
    }

    @Test func emptyIsShownOnlyAfterLoading() async throws {
        defer { observeTask.cancel() }
        let notLoaded = MemoListUiState()
        #expect(!notLoaded.showEmpty) // 読み込み前は「メモがありません」を出さない
        try await waitUntil { !viewModel.uiState.isLoading }
        #expect(viewModel.uiState.showEmpty)
    }

    @Test func listsMemoTabMemos() async throws {
        defer { observeTask.cancel() }
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "m", plainText: "m", now: 1)
        try await waitUntil { viewModel.uiState.memos.map(\.id) == [id] }
        #expect(!viewModel.uiState.showEmpty)
    }

    @Test func deleteMovesToTrashAndOffersUndo() async throws {
        defer { observeTask.cancel() }
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "m", plainText: "m", now: 1)
        try await waitUntil { viewModel.uiState.memos.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onDeleteClick(try #require(viewModel.uiState.memos.first))

        #expect(await events.next() == .showMovedToTrash(memoId: id))
        try await waitUntil { viewModel.uiState.memos.isEmpty }

        await viewModel.onUndoDelete(memoId: id)
        try await waitUntil { viewModel.uiState.memos.map(\.id) == [id] }
    }

    @Test func pinnedMemoMovesToTop() async throws {
        defer { observeTask.cancel() }
        let older = try await container.memoRepository.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        let newer = try await container.memoRepository.createMemo(folderId: nil, html: "b", plainText: "b", now: 2)
        try await waitUntil { viewModel.uiState.memos.map(\.id) == [newer, older] }

        await viewModel.onSetPinned(try #require(viewModel.uiState.memos.last), pinned: true)

        try await waitUntil { viewModel.uiState.memos.map(\.id) == [older, newer] }
        #expect(viewModel.uiState.memos.first?.isPinned == true)
    }

    @Test func sortSelectionIsSavedAndApplied() async throws {
        defer { observeTask.cancel() }
        let long = try await container.memoRepository.createMemo(folderId: nil, html: "abc", plainText: "abc", now: 1)
        let short = try await container.memoRepository.createMemo(folderId: nil, html: "a", plainText: "a", now: 2)
        try await waitUntil { viewModel.uiState.memos.count == 2 }

        viewModel.onSortSelected(MemoSort(key: .charCount, ascending: false))

        try await waitUntil { viewModel.uiState.sort == MemoSort(key: .charCount, ascending: false) }
        #expect(viewModel.uiState.memos.map(\.id) == [long, short])
        #expect(container.settingsRepository.themeMode == .system) // ほかの設定は変わらない
    }

    /// ロックの付け外し → 一覧にロックが付き、お知らせを出す。
    @Test func lockAndUnlock() async throws {
        defer { observeTask.cancel() }
        _ = try await container.memoRepository.createMemo(folderId: nil, html: "m", plainText: "m", now: 1)
        try await waitUntil { viewModel.uiState.memos.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onSetLocked(try #require(viewModel.uiState.memos.first), locked: true)
        #expect(await events.next() == .showLockChanged(locked: true))
        try await waitUntil { viewModel.uiState.memos.first?.isLocked == true }

        await viewModel.onSetLocked(try #require(viewModel.uiState.memos.first), locked: false)
        #expect(await events.next() == .showLockChanged(locked: false))
        try await waitUntil { viewModel.uiState.memos.first?.isLocked == false }
    }
}
