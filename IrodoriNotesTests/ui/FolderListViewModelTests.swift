import Foundation
import Testing
@testable import IrodoriNotes

/// フォルダタブの ViewModel（Android 版の FolderListViewModelTest と同じ内容）。
struct FolderListViewModelTests {
    let container: AppContainer
    let viewModel: FolderListViewModel
    let observeTask: Task<Void, Never>

    init() throws {
        container = try makeTestContainer(now: 1_000).container
        viewModel = container.makeFolderListViewModel()
        let viewModel = viewModel
        observeTask = Task { await viewModel.observe() }
    }

    private func folder(_ id: Int64) async throws -> Folder {
        try #require(try await container.folderRepository.observeFolder(id: id).firstValue())
    }

    @Test func emptyIsShownOnlyAfterLoading() async throws {
        defer { observeTask.cancel() }
        try await waitUntil { !viewModel.uiState.isLoading }
        #expect(viewModel.uiState.showEmpty)
    }

    @Test func createFolder_opensIt() async throws {
        defer { observeTask.cancel() }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onCreateFolder(name: " 趣味 ", color: .green)

        guard case .openFolder(let id) = await events.next() else {
            Issue.record("フォルダを開くイベントが来ない")
            return
        }
        #expect(try await folder(id).name == "趣味")
        try await waitUntil { viewModel.uiState.folders.map(\.id) == [id] }
    }

    @Test func deleteEmptyFolder_movesToTrashWithoutConfirmation() async throws {
        defer { observeTask.cancel() }
        let id = try await container.folderRepository.createFolder(parentId: nil, name: "空", color: .default, now: 1)
        try await waitUntil { viewModel.uiState.folders.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onDeleteClick(try await folder(id))

        #expect(await events.next() == .showMovedToTrash(folderId: id))
        try await waitUntil { viewModel.uiState.folders.isEmpty }

        await viewModel.onUndoDelete(folderId: id)
        try await waitUntil { viewModel.uiState.folders.map(\.id) == [id] }
    }

    @Test func deleteFolderWithContents_asksFirst_thenMovesToTrash() async throws {
        defer { observeTask.cancel() }
        let id = try await container.folderRepository.createFolder(parentId: nil, name: "趣味", color: .default, now: 1)
        _ = try await container.folderRepository.createFolder(parentId: id, name: "読書", color: .default, now: 2)
        _ = try await container.memoRepository.createMemo(folderId: id, html: "m", plainText: "m", now: 3)
        var events = viewModel.events().makeAsyncIterator()

        let target = try await folder(id)
        await viewModel.onDeleteClick(target)

        guard case .confirmDelete(let asked, let contents) = await events.next() else {
            Issue.record("確認のイベントが来ない")
            return
        }
        #expect(asked.id == id)
        #expect(contents == FolderContents(folderCount: 1, memoCount: 1))
        #expect(try await container.folderRepository.observeFolder(id: id).firstValue() != nil) // まだ消えていない

        await viewModel.onDeleteConfirmed(target)
        #expect(await events.next() == .showMovedToTrash(folderId: id))
        #expect(try await container.folderRepository.observeFolder(id: id).firstValue() == nil)
    }

    @Test func updateFolder_changesNameAndColor() async throws {
        defer { observeTask.cancel() }
        let id = try await container.folderRepository.createFolder(parentId: nil, name: "Old", color: .default, now: 1)

        await viewModel.onUpdateFolder(try await folder(id), name: "New ", color: .pink)

        let updated = try await folder(id)
        #expect(updated.name == "New")
        #expect(updated.color == .pink)
        #expect(updated.updatedAt == 1) // 名前・色の変更では更新日は変わらない
    }

    @Test func pinnedFolderMovesToTop() async throws {
        defer { observeTask.cancel() }
        let older = try await container.folderRepository.createFolder(parentId: nil, name: "A", color: .default, now: 1)
        let newer = try await container.folderRepository.createFolder(parentId: nil, name: "B", color: .default, now: 2)
        try await waitUntil { viewModel.uiState.folders.map(\.id) == [newer, older] }

        await viewModel.onSetPinned(try await folder(older), pinned: true)

        try await waitUntil { viewModel.uiState.folders.map(\.id) == [older, newer] }
    }

    @Test func lockAndUnlock() async throws {
        defer { observeTask.cancel() }
        let id = try await container.folderRepository.createFolder(parentId: nil, name: "秘密", color: .default, now: 1)
        try await waitUntil { viewModel.uiState.folders.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onSetLocked(try await folder(id), locked: true)
        #expect(await events.next() == .showLockChanged(locked: true))
        try await waitUntil { viewModel.uiState.folders.first?.isLocked == true }
    }
}
