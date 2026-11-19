import Foundation
import GRDB
import Testing
@testable import IrodoriNotes

/// DB の作り（テーブル・列が Android 版と同じか、完全削除が中身まで消えるか）。
struct AppDatabaseTests {

    private func columns(_ table: String, in database: AppDatabase) async throws -> [String] {
        try await database.writer.read { db in try db.columns(in: table).map(\.name) }
    }

    /// Android 版の Room（MemoEntity / FolderEntity）と同じ列。将来バックアップを共通にしやすくするため。
    @Test func tablesHaveSameColumnsAsAndroid() async throws {
        let database = try AppDatabase.makeInMemory()

        #expect(try await columns("memos", in: database) == [
            "id", "folderId", "html", "plainText", "firstLine", "charCount", "createdAt", "updatedAt",
            "deletedAt", "deletedWithFolder", "isLocked", "isPinned",
        ])
        #expect(try await columns("folders", in: database) == [
            "id", "parentId", "name", "colorKey", "createdAt", "updatedAt",
            "deletedAt", "deletedWithParent", "isLocked", "isPinned",
        ])
    }

    @Test func deletingFolderCascadesToChildFoldersAndMemos() async throws {
        let repos = try TestRepositories()
        let parent = try await repos.folders.createFolder(parentId: nil, name: "P", color: .default, now: 1)
        let child = try await repos.folders.createFolder(parentId: parent, name: "C", color: .default, now: 1)
        let memo = try await repos.memos.createMemo(folderId: child, html: "m", plainText: "m", now: 1)

        try await repos.trash.deleteFolderPermanently(id: parent)

        #expect(try await repos.database.folderRecord(child) == nil)
        #expect(try await repos.database.memoRecord(memo) == nil)
    }

    /// アプリで使うファイルの DB も作れる（Application Support に memo.sqlite）。
    @Test func defaultDatabaseIsInApplicationSupport() throws {
        _ = try AppDatabase.makeDefault()
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        #expect(FileManager.default.fileExists(atPath: directory.appendingPathComponent(AppDatabase.fileName).path))
    }
}
