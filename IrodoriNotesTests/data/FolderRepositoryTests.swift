import Foundation
import Testing
@testable import IrodoriNotes

/// フォルダの Repository（Android 版の FolderRepositoryTest と同じ内容）。
struct FolderRepositoryTests {
    let repos: TestRepositories
    var memos: MemoRepository { repos.memos }
    var folders: FolderRepository { repos.folders }
    var db: AppDatabase { repos.database }

    init() throws {
        repos = try TestRepositories()
    }

    @Test func rootAndChildFoldersAreListedSeparately() async throws {
        let root = try await folders.createFolder(parentId: nil, name: "趣味", color: .green, now: 1)
        let child = try await folders.createFolder(parentId: root, name: "読書", color: .blue, now: 2)

        #expect(try await folders.observeRootFolders().firstValue().map(\.id) == [root])
        let children = try await folders.observeChildFolders(parentId: root).firstValue()
        #expect(children.map(\.id) == [child])
        #expect(children.first?.parentId == root)
    }

    @Test func itemCount_isDirectActiveMemosAndFolders() async throws {
        let root = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        _ = try await memos.createMemo(folderId: root, html: "a", plainText: "a", now: 10)
        let trashed = try await memos.createMemo(folderId: root, html: "b", plainText: "b", now: 11)
        try await memos.moveToTrash(id: trashed, now: 12)
        let child = try await folders.createFolder(parentId: root, name: "子", color: .default, now: 13)
        _ = try await memos.createMemo(folderId: child, html: "c", plainText: "c", now: 14) // 孫の階層は数えない

        let folder = try #require(try await folders.observeRootFolders().firstValue().first)

        #expect(folder.itemCount == 2) // メモa ＋ フォルダ「子」
    }

    @Test func getPath_returnsFromRootToFolder() async throws {
        let a = try await folders.createFolder(parentId: nil, name: "趣味", color: .default, now: 1)
        let b = try await folders.createFolder(parentId: a, name: "読書", color: .default, now: 1)
        let c = try await folders.createFolder(parentId: b, name: "小説", color: .default, now: 1)

        #expect(try await folders.getPath(id: c).map(\.name) == ["趣味", "読書", "小説"])
        #expect(try await folders.getPath(id: a).count == 1)
    }

    @Test func createFolder_upToMaxDepth_thenRejected() async throws {
        var parent: Int64? = nil
        for level in 0..<FolderPolicy.maxDepth {
            parent = try await folders.createFolder(parentId: parent, name: "L\(level)", color: .default, now: 1)
        }
        #expect(try await folders.getPath(id: try #require(parent)).count == FolderPolicy.maxDepth)

        await #expect(throws: FolderError.depthLimitReached) {
            _ = try await folders.createFolder(parentId: parent, name: "too deep", color: .default, now: 1)
        }
    }

    @Test func createFolder_touchesAllAncestors() async throws {
        let a = try await folders.createFolder(parentId: nil, name: "A", color: .default, now: 1)
        let b = try await folders.createFolder(parentId: a, name: "B", color: .default, now: 2)

        _ = try await folders.createFolder(parentId: b, name: "C", color: .default, now: 30)

        #expect(try await db.folderUpdatedAt(a) == 30)
        #expect(try await db.folderUpdatedAt(b) == 30)
    }

    @Test func memoChangesInSubfolder_touchAllAncestors() async throws {
        let a = try await folders.createFolder(parentId: nil, name: "A", color: .default, now: 1)
        let b = try await folders.createFolder(parentId: a, name: "B", color: .default, now: 1)
        let other = try await folders.createFolder(parentId: nil, name: "Other", color: .default, now: 1)

        let memo = try await memos.createMemo(folderId: b, html: "m", plainText: "m", now: 10)
        #expect(try await db.folderUpdatedAt(a) == 10)
        #expect(try await db.folderUpdatedAt(b) == 10)

        try await memos.moveToFolder(memoIds: [memo], targetFolderId: other, now: 20) // 移動元・移動先とも
        #expect(try await db.folderUpdatedAt(a) == 20)
        #expect(try await db.folderUpdatedAt(b) == 20)
        #expect(try await db.folderUpdatedAt(other) == 20)
    }

    @Test func updateFolder_changesNameAndColorWithoutTouchingUpdatedAt() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "Old", color: .default, now: 1)

        try await folders.updateFolder(id: folderId, name: "New", color: .pink)

        let folder = try #require(try await folders.observeFolder(id: folderId).firstValue())
        #expect(folder.name == "New")
        #expect(folder.color == .pink)
        #expect(folder.updatedAt == 1)
    }

    @Test func countContents_countsAllActiveLevels() async throws {
        let a = try await folders.createFolder(parentId: nil, name: "A", color: .default, now: 1)
        let b = try await folders.createFolder(parentId: a, name: "B", color: .default, now: 1)
        let c = try await folders.createFolder(parentId: b, name: "C", color: .default, now: 1)
        _ = try await memos.createMemo(folderId: a, html: "1", plainText: "1", now: 1)
        _ = try await memos.createMemo(folderId: c, html: "2", plainText: "2", now: 1)
        let trashed = try await memos.createMemo(folderId: c, html: "3", plainText: "3", now: 1)
        try await memos.moveToTrash(id: trashed, now: 2)

        #expect(try await folders.countContents(id: a) == FolderContents(folderCount: 2, memoCount: 2))
    }

    @Test func moveToTrash_trashesWholeTreeWithFlags_andTouchesParent() async throws {
        let parent = try await folders.createFolder(parentId: nil, name: "P", color: .default, now: 1)
        let a = try await folders.createFolder(parentId: parent, name: "A", color: .default, now: 1)
        let b = try await folders.createFolder(parentId: a, name: "B", color: .default, now: 1)
        let memoInB = try await memos.createMemo(folderId: b, html: "m", plainText: "m", now: 10)
        let trashedBefore = try await memos.createMemo(folderId: a, html: "t", plainText: "t", now: 11)
        try await memos.moveToTrash(id: trashedBefore, now: 12)

        try await folders.moveToTrash(id: a, now: 20)

        #expect(try await folders.observeChildFolders(parentId: parent).firstValue().isEmpty)
        #expect(try await folders.observeFolder(id: b).firstValue() == nil)
        let aRecord = try #require(try await db.folderRecord(a))
        #expect(aRecord.deletedAt == 20)
        #expect(!aRecord.deletedWithParent)
        #expect(try #require(try await db.folderRecord(b)).deletedWithParent)
        #expect(try #require(try await db.memoRecord(memoInB)).deletedWithFolder)
        // 先に単体で削除したメモは「フォルダと一緒に削除」扱いにしない
        #expect(try #require(try await db.memoRecord(trashedBefore)).deletedWithFolder == false)
        #expect(try await db.folderUpdatedAt(parent) == 20)
    }

    @Test func getFolderTree_listsActiveFoldersDepthFirstByName() async throws {
        let b = try await folders.createFolder(parentId: nil, name: "B", color: .default, now: 1)
        let a = try await folders.createFolder(parentId: nil, name: "A", color: .red, now: 1)
        _ = try await folders.createFolder(parentId: a, name: "A2", color: .default, now: 1)
        _ = try await folders.createFolder(parentId: a, name: "A1", color: .default, now: 1)
        let trashed = try await folders.createFolder(parentId: b, name: "B-trashed", color: .default, now: 1)
        try await folders.moveToTrash(id: trashed, now: 2)

        let tree = try await folders.getFolderTree()

        #expect(tree.map(\.name) == ["A", "A1", "A2", "B"])
        #expect(tree.map(\.depth) == [1, 2, 2, 1])
        #expect(tree.first?.color == .red)
    }
}
