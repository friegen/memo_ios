import Foundation
import Testing
@testable import IrodoriNotes

/// メモ編集画面の ViewModel（Android 版の MemoEditViewModelTest と同じ内容）。
/// Android 版は偽物の UseCase で呼ばれ方を確かめていたが、こちらはメモリ上の DB の本物の UseCase で、DB の中身を確かめる。
struct MemoEditViewModelTests {
    let container: AppContainer
    let clock: FixedClock
    /// テストでは自動保存までの時間を短くする（本物は3秒）
    let autoSaveDelay: Duration = .milliseconds(100)

    init() throws {
        (container, _, clock) = try makeTestContainer(now: 1_000)
    }

    private func makeViewModel(memoId: Int64? = nil, folderId: Int64? = nil) -> MemoEditViewModel {
        MemoEditViewModel(
            memoId: memoId,
            folderId: folderId,
            getMemo: container.makeGetMemoUseCase(),
            saveMemo: container.makeSaveMemoUseCase(),
            moveMemoToTrash: container.makeMoveMemoToTrashUseCase(),
            revertMemo: container.makeRevertMemoUseCase(),
            discardMemo: container.makeDiscardMemoUseCase(),
            observeEditorSettings: container.makeObserveEditorSettingsUseCase(),
            autoSaveDelay: autoSaveDelay)
    }

    private func text(_ string: String) -> NSAttributedString { NSAttributedString(string: string) }

    private func memoTabMemos() async throws -> [MemoSummary] {
        try await container.memoRepository.observeMemoTabMemos().firstValue()
    }

    @Test func newMemo_emptyAndCountsFollowTyping() async throws {
        let viewModel = makeViewModel()
        var events = viewModel.events().makeAsyncIterator()
        await viewModel.load()

        #expect(await events.next() == .setInitialText(html: "", isNewMemo: true))
        #expect(!viewModel.uiState.isLoading)
        #expect(viewModel.uiState.isEmpty)

        viewModel.onContentChanged(text("ab\n😀"))
        try await waitUntil { viewModel.uiState.charCount == 3 }
        #expect(viewModel.uiState.lineCount == 2)
        #expect(!viewModel.uiState.isEmpty)
    }

    @Test func autoSave_afterTypingStops_thenUsesCreatedId() async throws {
        let folder = try await container.folderRepository.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let viewModel = makeViewModel(folderId: folder)
        await viewModel.load()

        viewModel.onContentChanged(text("a"))
        viewModel.onContentChanged(text("ab")) // 自動保存の前に入力 → 前の保存は取り消し
        try await Task.sleep(for: autoSaveDelay * 3)
        await viewModel.waitForPendingSaves()

        let saved = try await container.memoRepository.observeFolderMemos(folderId: folder).firstValue()
        #expect(saved.map(\.firstLine) == ["ab"]) // "a" では保存していない（1件だけ）

        clock.nowValue = 2_000
        viewModel.onContentChanged(text("abc"))
        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()
        let updated = try await container.memoRepository.observeFolderMemos(folderId: folder).firstValue()
        #expect(updated.map(\.firstLine) == ["abc"]) // 作ったメモを更新した（二重に作らない）
        #expect(updated.first?.updatedAt == 2_000)
    }

    @Test func existingMemo_sendsStoredHtml() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "a&lt;b<br>c", plainText: "a<b\nc", now: 1)
        let viewModel = makeViewModel(memoId: id)
        var events = viewModel.events().makeAsyncIterator()
        await viewModel.load()

        #expect(await events.next() == .setInitialText(html: "a&lt;b<br>c", isNewMemo: false))
        try await waitUntil { viewModel.uiState.charCount == 4 }
        #expect(viewModel.uiState.lineCount == 2)
    }

    @Test func missingMemo_closesAndNeverSaves() async throws {
        let viewModel = makeViewModel(memoId: 999)
        var events = viewModel.events().makeAsyncIterator()
        await viewModel.load()

        #expect(await events.next() == .notFound)
        viewModel.onContentChanged(text("x"))
        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()
        #expect(try await memoTabMemos().isEmpty)
    }

    @Test func confirmDelete_onlyForSavedMemoMadeEmpty() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        let viewModel = makeViewModel(memoId: id)
        await viewModel.load()

        #expect(!viewModel.shouldConfirmDeleteOnLeave) // 本文あり
        viewModel.onContentChanged(text(" \n"))
        #expect(viewModel.shouldConfirmDeleteOnLeave) // 空白だけ

        let newMemo = makeViewModel()
        await newMemo.load()
        newMemo.onContentChanged(text(""))
        #expect(!newMemo.shouldConfirmDeleteOnLeave) // 一度も保存していない新規メモは確認不要
    }

    @Test func deleteConfirmed_movesToTrashAndStopsSaving() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        let viewModel = makeViewModel(memoId: id)
        await viewModel.load()

        viewModel.onContentChanged(text(""))
        viewModel.onDeleteConfirmed()
        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()

        let record = try #require(try await container.database.memoRecord(id))
        #expect(record.deletedAt != nil) // ゴミ箱へ
        #expect(record.plainText == "a") // 空の内容は保存していない
        #expect(!viewModel.shouldConfirmDeleteOnLeave)
    }

    @Test func unchangedContent_isNotSavedAgain() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        let viewModel = makeViewModel(memoId: id)
        await viewModel.load()

        clock.nowValue = 5_000
        viewModel.onContentChanged(text("a"))
        try await Task.sleep(for: autoSaveDelay * 3)
        viewModel.onLeave(isClosing: false)
        await viewModel.waitForPendingSaves()

        #expect(try await container.memoRepository.getMemo(id: id)?.updatedAt == 1) // 更新日は進まない
    }

    @Test func leave_savesImmediatelyWithoutWaitingForAutoSave() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.onContentChanged(text("すぐ保存"))
        viewModel.onLeave(isClosing: false) // アプリが裏に回った
        await viewModel.waitForPendingSaves()

        #expect(try await memoTabMemos().map(\.firstLine) == ["すぐ保存"])
    }

    @Test func revertAndClose_restoresOriginalOnlyWhenSomethingWasSaved() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "abc", plainText: "abc", now: 10)
        let viewModel = makeViewModel(memoId: id)
        await viewModel.load()

        clock.nowValue = 2_000
        viewModel.onContentChanged(text("a"))
        try await Task.sleep(for: autoSaveDelay * 3) // 途中の "a" が保存される
        await viewModel.waitForPendingSaves()
        #expect(try await container.memoRepository.getMemo(id: id)?.plainText == "a")

        viewModel.onContentChanged(text(""))
        viewModel.onRevertAndClose()
        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()

        let memo = try #require(try await container.memoRepository.getMemo(id: id))
        #expect(memo.plainText == "abc") // 開いたときの本文
        #expect(memo.updatedAt == 10) // 開いたときの更新日
    }

    @Test func revertAndClose_withoutIntermediateSave_doesNothing() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "abc", plainText: "abc", now: 10)
        let viewModel = makeViewModel(memoId: id)
        await viewModel.load()

        viewModel.onContentChanged(text(""))
        viewModel.onRevertAndClose()
        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()

        let memo = try #require(try await container.memoRepository.getMemo(id: id))
        #expect(memo.plainText == "abc")
        #expect(memo.updatedAt == 10)
    }

    @Test func memoCreatedHere_clearedAndClosed_isDiscarded() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.onContentChanged(text("x"))
        try await Task.sleep(for: autoSaveDelay * 3)
        await viewModel.waitForPendingSaves()
        #expect(try await memoTabMemos().count == 1) // 途中で保存された

        viewModel.onContentChanged(text(""))
        #expect(!viewModel.shouldConfirmDeleteOnLeave) // ここで作ったメモは確認しない
        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()

        #expect(try await memoTabMemos().isEmpty)
        let trash = try await container.trashRepository.observeTrashItems().firstValue()
        #expect(trash.isEmpty) // ゴミ箱も通さずに消える
    }

    @Test func newMemo_closedWithoutTyping_isNotCreated() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.onLeave(isClosing: true)
        await viewModel.waitForPendingSaves()

        #expect(try await memoTabMemos().isEmpty)
    }

    @Test func selectedCharCount_excludesLineBreaks() async throws {
        let viewModel = makeViewModel()
        await viewModel.load()

        viewModel.onSelectionChanged(selectedText: "ab\nc😀")
        #expect(viewModel.uiState.selectedCharCount == 4)
        viewModel.onSelectionChanged(selectedText: nil)
        #expect(viewModel.uiState.selectedCharCount == nil)
    }

    @Test func followsEditorSettings() async throws {
        let viewModel = makeViewModel()
        let task = Task { await viewModel.observeSettings() }
        defer { task.cancel() }

        container.settingsRepository.setFontSize(.extraLarge)

        try await waitUntil { viewModel.uiState.editorSettings.fontSize == .extraLarge }
    }
}
