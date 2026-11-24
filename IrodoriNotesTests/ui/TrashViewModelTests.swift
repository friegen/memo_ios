import Foundation
import Testing
@testable import IrodoriNotes

/// ゴミ箱の ViewModel（Android 版の TrashViewModelTest と同じ内容）。
struct TrashViewModelTests {
    let container: AppContainer
    let viewModel: TrashViewModel
    let observeTask: Task<Void, Never>

    init() throws {
        container = try makeTestContainer(now: 1_000).container
        viewModel = container.makeTrashViewModel()
        let viewModel = viewModel
        observeTask = Task { await viewModel.observe() }
    }

    private var memos: MemoRepository { container.memoRepository }
    private var folders: FolderRepository { container.folderRepository }

    private func item(_ id: String) throws -> TrashItem {
        try #require(viewModel.uiState.items.first { $0.id == id })
    }

    @Test func emptyIsShownOnlyAfterLoading() async throws {
        defer { observeTask.cancel() }
        #expect(!viewModel.uiState.showEmpty)
        try await waitUntil { !viewModel.uiState.isLoading }
        #expect(viewModel.uiState.showEmpty)
        #expect(!viewModel.uiState.canEmpty)
    }

    /// 上の階層がゴミ箱にないメモは、確認せずに戻してお知らせを出す。
    @Test func restoreMemo_withoutConfirmation() async throws {
        defer { observeTask.cancel() }
        let memoId = try await memos.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        try await memos.moveToTrash(id: memoId, now: 2)
        try await waitUntil { viewModel.uiState.items.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onRestoreClick(try item("memo-\(memoId)"))

        #expect(await events.next() == .showRestored)
        try await waitUntil { viewModel.uiState.items.isEmpty }
        #expect(try #require(try await container.database.memoRecord(memoId)).deletedAt == nil)
    }

    /// 元のフォルダもゴミ箱にあるメモは「フォルダごと復元しますか？」を確認してから、フォルダごと戻す。
    @Test func restoreMemoWhoseFolderIsInTrash_asksFirst() async throws {
        defer { observeTask.cancel() }
        let folderId = try await folders.createFolder(parentId: nil, name: "旅行", color: .green, now: 1)
        let memoId = try await memos.createMemo(folderId: folderId, html: "a", plainText: "a", now: 2)
        try await memos.moveToTrash(id: memoId, now: 3)
        try await folders.moveToTrash(id: folderId, now: 4)
        try await waitUntil { viewModel.uiState.items.count == 2 }
        var events = viewModel.events().makeAsyncIterator()

        let memoItem = try item("memo-\(memoId)")
        await viewModel.onRestoreClick(memoItem)
        #expect(await events.next() == .confirmRestoreWithFolder(memoItem))
        #expect(viewModel.uiState.items.count == 2) // まだ戻していない

        await viewModel.onRestoreConfirmed(memoItem)
        #expect(await events.next() == .showRestored)
        try await waitUntil { viewModel.uiState.items.isEmpty }
        #expect(try await folders.observeFolder(id: folderId).firstValue() != nil)
    }

    @Test func deleteMemoPermanently_asksFirst() async throws {
        defer { observeTask.cancel() }
        let memoId = try await memos.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        try await memos.moveToTrash(id: memoId, now: 2)
        try await waitUntil { viewModel.uiState.items.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        let memoItem = try item("memo-\(memoId)")
        await viewModel.onDeletePermanentlyClick(memoItem)
        guard case .confirmDeleteMemo(let asked) = await events.next() else {
            Issue.record("確認のイベントが来ない")
            return
        }
        #expect(asked.memo.id == memoId)

        await viewModel.onDeleteMemoConfirmed(memoId: memoId)
        #expect(await events.next() == .showDeleted)
        try await waitUntil { viewModel.uiState.items.isEmpty }
        #expect(try await container.database.memoRecord(memoId) == nil)
    }

    /// フォルダの完全削除は、一緒に消える中身の数を出して確認する。
    @Test func deleteFolderPermanently_asksWithContents() async throws {
        defer { observeTask.cancel() }
        let folderId = try await folders.createFolder(parentId: nil, name: "旅行", color: .green, now: 1)
        _ = try await folders.createFolder(parentId: folderId, name: "ホテル", color: .default, now: 2)
        let memoId = try await memos.createMemo(folderId: folderId, html: "a", plainText: "a", now: 3)
        try await folders.moveToTrash(id: folderId, now: 4)
        try await waitUntil { viewModel.uiState.items.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onDeletePermanentlyClick(try item("folder-\(folderId)"))
        guard case .confirmDeleteFolder(let asked, let contents) = await events.next() else {
            Issue.record("確認のイベントが来ない")
            return
        }
        #expect(asked.folder.id == folderId)
        #expect(contents == FolderContents(folderCount: 1, memoCount: 1))

        await viewModel.onDeleteFolderConfirmed(folderId: folderId)
        #expect(await events.next() == .showDeleted)
        try await waitUntil { viewModel.uiState.items.isEmpty }
        #expect(try await container.database.memoRecord(memoId) == nil)
    }

    @Test func emptyTrash_asksFirst() async throws {
        defer { observeTask.cancel() }
        try await waitUntil { !viewModel.uiState.isLoading }
        var events = viewModel.events().makeAsyncIterator()
        viewModel.onEmptyTrashClick() // 空のときは何もしない

        let memoId = try await memos.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        try await memos.moveToTrash(id: memoId, now: 2)
        try await waitUntil { viewModel.uiState.canEmpty }

        viewModel.onEmptyTrashClick()
        #expect(await events.next() == .confirmEmptyTrash)

        await viewModel.onEmptyTrashConfirmed()
        #expect(await events.next() == .showEmptied)
        try await waitUntil { viewModel.uiState.items.isEmpty }
    }
}
