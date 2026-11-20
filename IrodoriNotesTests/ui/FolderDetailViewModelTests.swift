import Foundation
import Testing
@testable import IrodoriNotes

/// フォルダの中の ViewModel（Android 版の FolderDetailViewModelTest にあたる）。
struct FolderDetailViewModelTests {
    let container: AppContainer

    init() throws {
        container = try makeTestContainer(now: 1_000).container
    }

    private var folders: FolderRepository { container.folderRepository }
    private var memos: MemoRepository { container.memoRepository }

    /// ViewModel を作って監視を始める（終わったら task.cancel() する）。
    private func start(_ folderId: Int64) -> (FolderDetailViewModel, Task<Void, Never>) {
        let viewModel = container.makeFolderDetailViewModel(folderId: folderId)
        let task = Task { await viewModel.observe() }
        return (viewModel, task)
    }

    @Test func stateCombinesFolderAncestorsFoldersAndMemos() async throws {
        let hobby = try await folders.createFolder(parentId: nil, name: "趣味", color: .blue, now: 1)
        let reading = try await folders.createFolder(parentId: hobby, name: "読書", color: .green, now: 2)
        let novel = try await folders.createFolder(parentId: reading, name: "小説", color: .default, now: 3)
        let memo = try await memos.createMemo(folderId: reading, html: "m", plainText: "m", now: 4)
        let (viewModel, task) = start(reading)
        defer { task.cancel() }

        try await waitUntil { !viewModel.uiState.isLoading }
        let state = viewModel.uiState
        #expect(state.folder?.name == "読書")
        #expect(state.ancestors.map(\.name) == ["趣味"]) // 上の階層（サブタイトル）
        #expect(state.folders.map(\.id) == [novel])
        #expect(state.memos.map(\.id) == [memo])
        #expect(state.canCreateFolder)
        #expect(!state.showEmpty)
    }

    @Test func cannotCreateFolderAtMaxDepth() async throws {
        var ids: [Int64] = []
        for level in 1...FolderPolicy.maxDepth {
            ids.append(try await folders.createFolder(parentId: ids.last, name: "L\(level)", color: .default, now: 1))
        }
        let deepest = ids[FolderPolicy.maxDepth - 1]
        let (viewModel, task) = start(deepest)
        defer { task.cancel() }
        try await waitUntil { !viewModel.uiState.isLoading }

        #expect(!viewModel.uiState.canCreateFolder)
        #expect(viewModel.uiState.showEmpty)
        await viewModel.onCreateFolder(name: "too deep", color: .default) // 何も起きない
        #expect(try await folders.observeChildFolders(parentId: deepest).firstValue().isEmpty)

        // 4階層目なら作れる
        let (fourth, fourthTask) = start(ids[FolderPolicy.maxDepth - 2])
        defer { fourthTask.cancel() }
        try await waitUntil { !fourth.uiState.isLoading }
        #expect(fourth.uiState.canCreateFolder)
    }

    @Test func addFolder_showsSheet_thenCreateOpensIt() async throws {
        let hobby = try await folders.createFolder(parentId: nil, name: "趣味", color: .blue, now: 1)
        let (viewModel, task) = start(hobby)
        defer { task.cancel() }
        try await waitUntil { !viewModel.uiState.isLoading }
        var events = viewModel.events().makeAsyncIterator()

        viewModel.onAddFolderClick()
        #expect(await events.next() == .showCreateFolderSheet)

        await viewModel.onCreateFolder(name: "読書", color: .green)
        guard case .openFolder(let id) = await events.next() else {
            Issue.record("作ったフォルダを開くイベントが来ない")
            return
        }
        #expect(try await folders.getPath(id: id).map(\.name) == ["趣味", "読書"])
    }

    @Test func moveMemo_toAnotherFolder() async throws {
        let from = try await folders.createFolder(parentId: nil, name: "A", color: .default, now: 1)
        let to = try await folders.createFolder(parentId: nil, name: "B", color: .default, now: 1)
        let memo = try await memos.createMemo(folderId: from, html: "m", plainText: "m", now: 2)
        let (viewModel, task) = start(from)
        defer { task.cancel() }
        try await waitUntil { viewModel.uiState.memos.count == 1 }
        var events = viewModel.events().makeAsyncIterator()
        let summary = try #require(viewModel.uiState.memos.first)

        await viewModel.onMoveMemoClick(summary)
        guard case .chooseMoveTarget(_, let targets) = await events.next() else {
            Issue.record("移動先を選ぶイベントが来ない")
            return
        }
        #expect(targets.map(\.name) == ["A", "B"]) // 今いるフォルダも出す（画面で選べなくする）

        await viewModel.onMoveTargetSelected(summary, target: try #require(targets.first { $0.id == from }))
        #expect(try await memos.observeFolderMemos(folderId: from).firstValue().count == 1) // 今いるフォルダには移さない

        await viewModel.onMoveTargetSelected(summary, target: try #require(targets.first { $0.id == to }))
        #expect(await events.next() == .showMemoMoved(targetName: "B"))
        #expect(try await memos.observeFolderMemos(folderId: to).firstValue().map(\.id) == [memo])
        try await waitUntil { viewModel.uiState.memos.isEmpty }
    }

    @Test func moveMemo_noOtherFolders() async throws {
        let only = try await folders.createFolder(parentId: nil, name: "Only", color: .default, now: 1)
        _ = try await memos.createMemo(folderId: only, html: "m", plainText: "m", now: 2)
        let (viewModel, task) = start(only)
        defer { task.cancel() }
        try await waitUntil { viewModel.uiState.memos.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onMoveMemoClick(try #require(viewModel.uiState.memos.first))

        #expect(await events.next() == .showNoMoveTargets)
    }

    /// 開いているフォルダがゴミ箱に入ったら（別の画面で削除されたなど）、前の画面に戻る。
    @Test func closesWhenFolderIsTrashed() async throws {
        let parent = try await folders.createFolder(parentId: nil, name: "P", color: .default, now: 1)
        let child = try await folders.createFolder(parentId: parent, name: "C", color: .default, now: 1)
        let (viewModel, task) = start(child)
        defer { task.cancel() }
        try await waitUntil { !viewModel.uiState.isLoading }
        var events = viewModel.events().makeAsyncIterator()

        try await folders.moveToTrash(id: parent, now: 2) // 上の階層ごと削除

        #expect(await events.next() == .close)
    }

    @Test func deleteMemoAndUndo() async throws {
        let folder = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let memo = try await memos.createMemo(folderId: folder, html: "m", plainText: "m", now: 2)
        let (viewModel, task) = start(folder)
        defer { task.cancel() }
        try await waitUntil { viewModel.uiState.memos.count == 1 }
        var events = viewModel.events().makeAsyncIterator()

        await viewModel.onDeleteMemoClick(try #require(viewModel.uiState.memos.first))
        #expect(await events.next() == .showMemoMovedToTrash(memoId: memo))
        try await waitUntil { viewModel.uiState.showEmpty }

        await viewModel.onUndoDeleteMemo(memoId: memo)
        try await waitUntil { viewModel.uiState.memos.count == 1 }
    }

    @Test func memoAndFolderSortsAreSavedSeparately() async throws {
        let folder = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let (viewModel, task) = start(folder)
        defer { task.cancel() }
        try await waitUntil { !viewModel.uiState.isLoading }

        viewModel.onMemoSortSelected(MemoSort(key: .charCount, ascending: true))
        viewModel.onFolderSortSelected(FolderSort(key: .name, ascending: true))

        try await waitUntil {
            viewModel.uiState.memoSort == MemoSort(key: .charCount, ascending: true)
                && viewModel.uiState.folderSort == FolderSort(key: .name, ascending: true)
        }
        // メモタブの並び順は変わらない（フォルダ内のメモの並び順は別に持つ）
        #expect(try await container.settingsRepository.observeMemoTabSort().firstValue() == MemoSort())
    }
}
