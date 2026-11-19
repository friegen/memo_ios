import Foundation
import Testing
@testable import IrodoriNotes

/// メモの Repository（Android 版の MemoRepositoryTest と同じ内容）。
struct MemoRepositoryTests {
    let repos: TestRepositories
    var memos: MemoRepository { repos.memos }
    var folders: FolderRepository { repos.folders }
    var db: AppDatabase { repos.database }

    init() throws {
        repos = try TestRepositories()
    }

    @Test func setPinned_showsInListWithoutChangingUpdatedAt() async throws {
        let folder = try await folders.createFolder(parentId: nil, name: "F", color: .blue, now: 1)
        let id = try await memos.createMemo(folderId: folder, html: "m", plainText: "m", now: 2)
        let folderUpdated = try await db.folderUpdatedAt(folder)

        try await memos.setPinned(id: id, pinned: true)
        try await folders.setPinned(id: folder, pinned: true)

        let summary = try #require(try await memos.observeFolderMemos(folderId: folder).firstValue().first)
        #expect(summary.isPinned)
        #expect(summary.updatedAt == 2) // 中身は変わらないので更新日はそのまま
        let pinnedFolder = try #require(try await folders.observeFolder(id: folder).firstValue())
        #expect(pinnedFolder.isPinned)
        #expect(try await db.folderUpdatedAt(folder) == folderUpdated)

        try await memos.setPinned(id: id, pinned: false)
        #expect(try await memos.observeFolderMemos(folderId: folder).firstValue().first?.isPinned == false)
    }

    @Test func setLocked_showsInListAndMemoWithLockedFolders() async throws {
        let parent = try await folders.createFolder(parentId: nil, name: "親", color: .blue, now: 1)
        let child = try await folders.createFolder(parentId: parent, name: "子", color: .blue, now: 1)
        let id = try await memos.createMemo(folderId: child, html: "m", plainText: "m", now: 2)

        #expect(try #require(try await memos.getMemo(id: id)).isProtected == false)

        try await memos.setLocked(id: id, locked: true)
        try await folders.setLocked(id: parent, locked: true)

        #expect(try await memos.observeFolderMemos(folderId: child).firstValue().first?.isLocked == true)
        let memo = try #require(try await memos.getMemo(id: id))
        #expect(memo.isLocked)
        #expect(memo.lockedFolderIds == [parent]) // 上の階層のロックも分かる
        #expect(try await folders.getPath(id: child).first?.isLocked == true)
        #expect(try await folders.observeFolder(id: parent).firstValue()?.isLocked == true)

        try await memos.setLocked(id: id, locked: false)
        try await folders.setLocked(id: parent, locked: false)
        #expect(try #require(try await memos.getMemo(id: id)).isProtected == false)
    }

    @Test func createMemo_memoTabAndFolderAreSeparate() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "F", color: .blue, now: 1)
        let tabMemoId = try await memos.createMemo(folderId: nil, html: "tab", plainText: "tab", now: 10)
        let folderMemoId = try await memos.createMemo(folderId: folderId, html: "in folder", plainText: "in folder", now: 20)

        #expect(try await memos.observeMemoTabMemos().firstValue().map(\.id) == [tabMemoId])
        #expect(try await memos.observeFolderMemos(folderId: folderId).firstValue().map(\.id) == [folderMemoId])
    }

    @Test func createMemo_calculatesCharCountFirstLineAndDates() async throws {
        let id = try await memos.createMemo(folderId: nil, html: "ab<br>😀", plainText: "\n ab \n😀", now: 100)
        let memo = try #require(try await memos.getMemo(id: id))

        #expect(memo.charCount == 5) // 空白 + a + b + 空白 + 😀（改行は数えない）
        #expect(memo.createdAt == 100)
        #expect(memo.updatedAt == 100)

        let summary = try #require(try await memos.observeMemoTabMemos().firstValue().first)
        #expect(summary.firstLine == "ab")
        #expect(summary.charCount == 5)
        #expect(!summary.isUpdated)
    }

    @Test func firstLine_isLimitedAndFollowsUpdates() async throws {
        let long = String(repeating: "あ", count: 80)
        let id = try await memos.createMemo(folderId: nil, html: long, plainText: long, now: 1)
        #expect(try await memos.observeMemoTabMemos().firstValue().first?.firstLine.count == MemoPolicy.firstLineMaxChars)

        try await memos.updateMemo(id: id, html: "新しい", plainText: "新しい1行目\n2行目", now: 2)
        #expect(try await memos.observeMemoTabMemos().firstValue().first?.firstLine == "新しい1行目")
    }

    /// 本文がとても長いメモがあっても、一覧は表示できること（一覧では本文を読まない）。
    @Test func hugeMemo_doesNotBreakList() async throws {
        let huge = String(repeating: "あ", count: 1_200_000) // UTF-8 で約3.6MB
        _ = try await memos.createMemo(folderId: nil, html: huge, plainText: huge, now: 1)
        _ = try await memos.createMemo(folderId: nil, html: "small", plainText: "small", now: 2)

        let list = try await memos.observeMemoTabMemos().firstValue()

        #expect(list.count == 2)
        #expect(list.first { $0.firstLine.hasPrefix("あ") }?.charCount == 1_200_000)
    }

    @Test func createMemo_inFolder_touchesFolderUpdatedAt() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        _ = try await memos.createMemo(folderId: folderId, html: "x", plainText: "x", now: 50)

        #expect(try await db.folderUpdatedAt(folderId) == 50)
    }

    @Test func updateMemo_changesContentAndTouchesFolder() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let id = try await memos.createMemo(folderId: folderId, html: "a", plainText: "a", now: 10)

        let updated = try await memos.updateMemo(id: id, html: "abc", plainText: "abc", now: 20)

        #expect(updated)
        let memo = try #require(try await memos.getMemo(id: id))
        #expect(memo.plainText == "abc")
        #expect(memo.charCount == 3)
        #expect(memo.createdAt == 10)
        #expect(memo.updatedAt == 20)
        #expect(try await db.folderUpdatedAt(folderId) == 20)
    }

    @Test func updateMemo_sameContent_doesNothing() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let id = try await memos.createMemo(folderId: folderId, html: "a", plainText: "a", now: 10)

        let updated = try await memos.updateMemo(id: id, html: "a", plainText: "a", now: 20)

        #expect(!updated)
        #expect(try #require(try await memos.getMemo(id: id)).updatedAt == 10)
        #expect(try await db.folderUpdatedAt(folderId) == 10)
    }

    @Test func moveToFolder_movesAndTouchesBothFoldersButNotMemo() async throws {
        let from = try await folders.createFolder(parentId: nil, name: "A", color: .default, now: 1)
        let to = try await folders.createFolder(parentId: nil, name: "B", color: .default, now: 1)
        let id = try await memos.createMemo(folderId: from, html: "m", plainText: "m", now: 10)

        try await memos.moveToFolder(memoIds: [id], targetFolderId: to, now: 30)

        #expect(try await memos.observeFolderMemos(folderId: from).firstValue().isEmpty)
        #expect(try await memos.observeFolderMemos(folderId: to).firstValue().map(\.id) == [id])
        #expect(try await db.folderUpdatedAt(from) == 30)
        #expect(try await db.folderUpdatedAt(to) == 30)
        #expect(try #require(try await memos.getMemo(id: id)).updatedAt == 10)
    }

    @Test func moveToTrash_hidesFromListAndTouchesFolder() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let id = try await memos.createMemo(folderId: folderId, html: "m", plainText: "m", now: 10)

        try await memos.moveToTrash(id: id, now: 40)

        #expect(try await memos.observeFolderMemos(folderId: folderId).firstValue().isEmpty)
        #expect(try await memos.getMemo(id: id) == nil)
        #expect(try await db.folderUpdatedAt(folderId) == 40)
        let record = try #require(try await db.memoRecord(id))
        #expect(record.deletedAt == 40)
        #expect(!record.deletedWithFolder)
    }

    @Test func revertMemo_restoresContentAndUpdatedAt() async throws {
        let id = try await memos.createMemo(folderId: nil, html: "abc", plainText: "abc", now: 10)
        try await memos.updateMemo(id: id, html: "a", plainText: "a", now: 20)

        try await memos.revertMemo(id: id, html: "abc", plainText: "abc", updatedAt: 10)

        let memo = try #require(try await memos.getMemo(id: id))
        #expect(memo.plainText == "abc")
        #expect(memo.charCount == 3)
        #expect(memo.updatedAt == 10)
        #expect(try await memos.observeMemoTabMemos().firstValue().first?.firstLine == "abc")
    }

    /// DB の中身が変わると、監視している一覧に新しい値が流れる（Room の Flow と同じ動き）。
    @Test func observeMemoTabMemos_emitsAfterChange() async throws {
        var iterator = memos.observeMemoTabMemos().makeAsyncIterator()
        #expect(try await iterator.next()?.isEmpty == true)

        let id = try await memos.createMemo(folderId: nil, html: "new", plainText: "new", now: 1)

        #expect(try await iterator.next()?.map(\.id) == [id])
    }
}
