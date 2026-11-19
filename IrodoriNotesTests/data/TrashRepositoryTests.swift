import Foundation
import Testing
@testable import IrodoriNotes

/// ゴミ箱の Repository（Android 版の TrashRepositoryTest と同じ内容）。
struct TrashRepositoryTests {
    let repos: TestRepositories
    var memos: MemoRepository { repos.memos }
    var folders: FolderRepository { repos.folders }
    var trash: TrashRepository { repos.trash }
    var db: AppDatabase { repos.database }

    init() throws {
        repos = try TestRepositories()
    }

    private func trashItems() async throws -> [TrashItem] {
        try await trash.observeTrashItems().firstValue()
    }

    private func trashedMemos() async throws -> [TrashedMemo] {
        try await trashItems().compactMap { if case .memo(let item) = $0 { item } else { nil } }
    }

    private func trashedFolders() async throws -> [TrashedFolder] {
        try await trashItems().compactMap { if case .folder(let item) = $0 { item } else { nil } }
    }

    /// フォルダA にメモA・メモB → メモA を単体削除 → フォルダA を削除、の状態を作る。
    private func setUpMemoThenFolderDeleted() async throws -> (folderA: Int64, memoA: Int64, memoB: Int64) {
        let folderA = try await folders.createFolder(parentId: nil, name: "フォルダA", color: .blue, now: 1)
        let memoA = try await memos.createMemo(folderId: folderA, html: "A", plainText: "A", now: 10)
        let memoB = try await memos.createMemo(folderId: folderA, html: "B", plainText: "B", now: 11)
        try await memos.moveToTrash(id: memoA, now: 100)
        try await folders.moveToTrash(id: folderA, now: 200)
        return (folderA, memoA, memoB)
    }

    @Test func observeTrashItems_showsFolderAsOneItemAndIndividualMemoSeparately() async throws {
        let (folderA, memoA, _) = try await setUpMemoThenFolderDeleted()

        let items = try await trashItems()

        #expect(items.count == 2)
        // 削除日時の新しい順: フォルダ(200) → メモA(100)
        guard case .folder(let folderItem) = items[0], case .memo(let memoItem) = items[1] else {
            Issue.record("並びがちがう: \(items)")
            return
        }
        #expect(folderItem.folder.id == folderA)
        #expect(folderItem.memoCount == 1) // 一緒に削除されたメモB だけ
        #expect(memoItem.memo.id == memoA)
        #expect(memoItem.folderName == "フォルダA")
        #expect(memoItem.isFolderInTrash)
    }

    @Test func observeTrashItems_lockedMemoAndFolderAreMarked() async throws {
        let locked = try await folders.createFolder(parentId: nil, name: "鍵", color: .blue, now: 1)
        let child = try await folders.createFolder(parentId: locked, name: "子", color: .blue, now: 1)
        let inLocked = try await memos.createMemo(folderId: locked, html: "a", plainText: "a", now: 2)
        let lockedMemo = try await memos.createMemo(folderId: nil, html: "b", plainText: "b", now: 3)
        let plain = try await memos.createMemo(folderId: nil, html: "c", plainText: "c", now: 4)
        try await folders.setLocked(id: locked, locked: true)
        try await memos.setLocked(id: lockedMemo, locked: true)
        try await memos.moveToTrash(id: inLocked, now: 10)
        try await memos.moveToTrash(id: lockedMemo, now: 11)
        try await memos.moveToTrash(id: plain, now: 12)
        try await folders.moveToTrash(id: child, now: 13)

        let memoItems = Dictionary(uniqueKeysWithValues: try await trashedMemos().map { ($0.memo.id, $0) })
        #expect(memoItems[inLocked]?.isLocked == true) // ロックしたフォルダの中
        #expect(memoItems[lockedMemo]?.isLocked == true)
        #expect(memoItems[plain]?.isLocked == false)
        #expect(try await trashedFolders().first?.isLocked == true) // 上の階層がロック
    }

    @Test func observeTrashItems_memoTabMemoHasNoFolder() async throws {
        let id = try await memos.createMemo(folderId: nil, html: "m", plainText: "m", now: 1)
        try await memos.moveToTrash(id: id, now: 2)

        let item = try #require(try await trashedMemos().first)

        #expect(item.folderName == nil)
        #expect(!item.isFolderInTrash)
    }

    @Test func restoreFolder_restoresOnlyMemosDeletedWithFolder() async throws {
        let (folderA, memoA, memoB) = try await setUpMemoThenFolderDeleted()

        try await trash.restoreFolder(id: folderA, now: 300)

        #expect(try await memos.observeFolderMemos(folderId: folderA).firstValue().map(\.id) == [memoB])
        // 先に単体削除したメモA はゴミ箱に残る
        let remaining = try await trashedMemos()
        #expect(remaining.map(\.memo.id) == [memoA])
        #expect(remaining.first?.isFolderInTrash == false)
    }

    @Test func restoreMemo_whoseFolderIsInTrash_restoresFolderWithItsMemos() async throws {
        let (folderA, memoA, memoB) = try await setUpMemoThenFolderDeleted()
        #expect(try await trash.isParentFolderInTrash(memoId: memoA))

        try await trash.restoreMemo(id: memoA, now: 300)

        #expect(try await folders.observeFolder(id: folderA).firstValue() != nil)
        #expect(Set(try await memos.observeFolderMemos(folderId: folderA).firstValue().map(\.id)) == [memoA, memoB])
        #expect(try await trashItems().isEmpty)
        #expect(try await db.folderUpdatedAt(folderA) == 300)
    }

    @Test func restoreMemo_folderActive_restoresToOriginalFolder() async throws {
        let folderId = try await folders.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        let id = try await memos.createMemo(folderId: folderId, html: "m", plainText: "m", now: 10)
        try await memos.moveToTrash(id: id, now: 20)
        #expect(try await trash.isParentFolderInTrash(memoId: id) == false)

        try await trash.restoreMemo(id: id, now: 30)

        #expect(try await memos.observeFolderMemos(folderId: folderId).firstValue().map(\.id) == [id])
        #expect(try await db.folderUpdatedAt(folderId) == 30)
    }

    @Test func deleteFolderPermanently_alsoDeletesIndividuallyTrashedMemosOfFolder() async throws {
        let (folderA, memoA, memoB) = try await setUpMemoThenFolderDeleted()
        #expect(try await trash.countContentsOfTrashedFolder(id: folderA) == FolderContents(folderCount: 0, memoCount: 2))

        try await trash.deleteFolderPermanently(id: folderA)

        #expect(try await db.folderRecord(folderA) == nil)
        #expect(try await db.memoRecord(memoA) == nil)
        #expect(try await db.memoRecord(memoB) == nil)
        #expect(try await trashItems().isEmpty)
    }

    @Test func emptyTrash_deletesEverythingInTrashOnly() async throws {
        _ = try await setUpMemoThenFolderDeleted()
        let trashedTabMemo = try await memos.createMemo(folderId: nil, html: "t", plainText: "t", now: 1)
        try await memos.moveToTrash(id: trashedTabMemo, now: 2)
        let activeMemo = try await memos.createMemo(folderId: nil, html: "keep", plainText: "keep", now: 3)
        let activeFolder = try await folders.createFolder(parentId: nil, name: "keep", color: .default, now: 4)

        try await trash.emptyTrash()

        #expect(try await trashItems().isEmpty)
        #expect(try await memos.getMemo(id: activeMemo) != nil)
        #expect(try await folders.observeFolder(id: activeFolder).firstValue() != nil)
    }

    @Test func purgeExpired_deletesOnlyItemsOlderThanRetention() async throws {
        let day: Int64 = 24 * 60 * 60 * 1000
        let now = 100 * day
        let oldMemo = try await memos.createMemo(folderId: nil, html: "old", plainText: "old", now: 0)
        let newMemo = try await memos.createMemo(folderId: nil, html: "new", plainText: "new", now: 0)
        try await memos.moveToTrash(id: oldMemo, now: now - TrashPolicy.retentionMillis - 1)
        try await memos.moveToTrash(id: newMemo, now: now - TrashPolicy.retentionMillis + 1)
        let oldFolder = try await folders.createFolder(parentId: nil, name: "old", color: .default, now: 0)
        let memoInOldFolder = try await memos.createMemo(folderId: oldFolder, html: "x", plainText: "x", now: 0)
        try await folders.moveToTrash(id: oldFolder, now: now - TrashPolicy.retentionMillis - 1)

        try await trash.purgeExpired(now: now)

        #expect(try await db.memoRecord(oldMemo) == nil)
        #expect(try await db.memoRecord(newMemo) != nil)
        #expect(try await db.folderRecord(oldFolder) == nil)
        #expect(try await db.memoRecord(memoInOldFolder) == nil)
    }

    // MARK: フォルダの中のフォルダ（Android v1.4）

    /// P ＞ A ＞ B の3階層。A の中にメモ a、B の中にメモ b。
    private func nested() async throws -> (p: Int64, a: Int64, b: Int64, memoA: Int64, memoB: Int64) {
        let p = try await folders.createFolder(parentId: nil, name: "P", color: .default, now: 1)
        let a = try await folders.createFolder(parentId: p, name: "A", color: .default, now: 1)
        let b = try await folders.createFolder(parentId: a, name: "B", color: .default, now: 1)
        let memoA = try await memos.createMemo(folderId: a, html: "a", plainText: "a", now: 1)
        let memoB = try await memos.createMemo(folderId: b, html: "b", plainText: "b", now: 1)
        return (p, a, b, memoA, memoB)
    }

    @Test func nestedFolderDeleted_isOneItemWithCounts_andRestoresWholeTree() async throws {
        let ids = try await nested()
        try await folders.moveToTrash(id: ids.a, now: 100)

        let folderItems = try await trashedFolders()
        #expect(try await trashItems().count == 1)
        let item = try #require(folderItems.first)
        #expect(item.folder.id == ids.a)
        #expect(item.folderCount == 1) // B
        #expect(item.memoCount == 2) // a, b
        #expect(item.parentName == "P")
        #expect(!item.isParentInTrash)

        try await trash.restoreFolder(id: ids.a, now: 200)

        #expect(try await trashItems().isEmpty)
        #expect(try await folders.observeChildFolders(parentId: ids.a).firstValue().map(\.id) == [ids.b])
        #expect(try await memos.observeFolderMemos(folderId: ids.b).firstValue().map(\.id) == [ids.memoB])
        #expect(try await db.folderUpdatedAt(ids.p) == 200)
    }

    /// 先にサブフォルダ B を削除 → 親の A を削除。B を復元すると A も（確認のうえ）戻る。
    @Test func subfolderDeletedFirst_thenParent_restoringSubfolderRestoresParentToo() async throws {
        let ids = try await nested()
        try await folders.moveToTrash(id: ids.b, now: 100)
        try await folders.moveToTrash(id: ids.a, now: 200)

        #expect(try await trashItems().count == 2) // A と B がそれぞれ1項目
        let bItem = try #require(try await trashedFolders().first { $0.folder.id == ids.b })
        #expect(bItem.isParentInTrash)
        #expect(try await trash.isParentOfFolderInTrash(folderId: ids.b))

        try await trash.restoreFolder(id: ids.b, now: 300)

        #expect(try await trashItems().isEmpty)
        #expect(try await memos.observeFolderMemos(folderId: ids.a).firstValue().map(\.id) == [ids.memoA])
        #expect(try await memos.observeFolderMemos(folderId: ids.b).firstValue().map(\.id) == [ids.memoB])
    }

    /// 親の A を復元しても、先に単体で削除したサブフォルダ B はゴミ箱に残る。
    @Test func restoringParent_keepsIndividuallyDeletedSubfolderInTrash() async throws {
        let ids = try await nested()
        try await folders.moveToTrash(id: ids.b, now: 100)
        try await folders.moveToTrash(id: ids.a, now: 200)

        try await trash.restoreFolder(id: ids.a, now: 300)

        let remaining = try await trashedFolders()
        #expect(try await trashItems().count == 1)
        #expect(remaining.first?.folder.id == ids.b)
        #expect(remaining.first?.isParentInTrash == false)
    }

    /// 深い階層のメモを単体削除 → 上の P を削除。メモを復元すると P ＞ A ＞ B がすべて戻る。
    @Test func memoInDeepFolder_restoreBringsBackAllTrashedAncestors() async throws {
        let ids = try await nested()
        try await memos.moveToTrash(id: ids.memoB, now: 100)
        try await folders.moveToTrash(id: ids.p, now: 200)

        let memoItem = try #require(try await trashedMemos().first)
        #expect(memoItem.folderName == "B")
        #expect(memoItem.isFolderInTrash)

        try await trash.restoreMemo(id: ids.memoB, now: 300)

        #expect(try await folders.observeRootFolders().firstValue().map(\.id) == [ids.p])
        #expect(try await memos.observeFolderMemos(folderId: ids.b).firstValue().map(\.id) == [ids.memoB])
        #expect(try await memos.observeFolderMemos(folderId: ids.a).firstValue().map(\.id) == [ids.memoA])
        #expect(try await trashItems().isEmpty)
    }

    @Test func deleteNestedFolderPermanently_removesWholeTree() async throws {
        let ids = try await nested()
        try await memos.moveToTrash(id: ids.memoB, now: 100)
        try await folders.moveToTrash(id: ids.a, now: 200)
        #expect(try await trash.countContentsOfTrashedFolder(id: ids.a) == FolderContents(folderCount: 1, memoCount: 2))

        try await trash.deleteFolderPermanently(id: ids.a)

        #expect(try await db.folderRecord(ids.a) == nil)
        #expect(try await db.folderRecord(ids.b) == nil)
        #expect(try await db.memoRecord(ids.memoA) == nil)
        #expect(try await db.memoRecord(ids.memoB) == nil)
        #expect(try await db.folderRecord(ids.p) != nil)
        #expect(try await trashItems().isEmpty)
    }

    @Test func countContentsOfTrashedFolder_countsEverythingInsideIncludingIndividuallyTrashed() async throws {
        let parent = try await folders.createFolder(parentId: nil, name: "P", color: .default, now: 1)
        let child = try await folders.createFolder(parentId: parent, name: "C", color: .default, now: 1)
        let single = try await memos.createMemo(folderId: parent, html: "single", plainText: "single", now: 2)
        _ = try await memos.createMemo(folderId: child, html: "inChild", plainText: "inChild", now: 2)
        try await memos.moveToTrash(id: single, now: 3) // 先に単体で削除したメモも、完全削除では一緒に消える
        try await folders.moveToTrash(id: parent, now: 4)

        #expect(try await trash.countContentsOfTrashedFolder(id: parent) == FolderContents(folderCount: 1, memoCount: 2))
    }
}
