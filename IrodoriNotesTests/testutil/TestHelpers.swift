import Foundation
import GRDB
import Testing
@testable import IrodoriNotes

/// 値が1つも流れてこなかったとき。
struct NoValueError: Error {}

extension AsyncThrowingStream {
    /// 最初に流れてきた値（Android の Flow.first() にあたる）。
    func firstValue() async throws -> Element {
        for try await value in self { return value }
        throw NoValueError()
    }
}

extension AsyncStream {
    /// 最初に流れてきた値。
    func firstValue() async throws -> Element {
        for await value in self { return value }
        throw NoValueError()
    }
}

extension AppDatabase {
    /// テストで DB の行をそのまま見る（Android のテストの db.memoDao().findById にあたる）。
    func memoRecord(_ id: Int64) async throws -> MemoRecord? {
        try await writer.read { db in try MemoDao.findById(db, id: id) }
    }

    func folderRecord(_ id: Int64) async throws -> FolderRecord? {
        try await writer.read { db in try FolderDao.findById(db, id: id) }
    }

    func folderUpdatedAt(_ id: Int64) async throws -> Int64 {
        try #require(try await folderRecord(id)).updatedAt
    }
}

/// テスト用の DB と Repository 一式。
struct TestRepositories {
    let database: AppDatabase
    let memos: MemoRepository
    let folders: FolderRepository
    let trash: TrashRepository

    init() throws {
        database = try AppDatabase.makeInMemory()
        memos = MemoRepository(database: database)
        folders = FolderRepository(database: database)
        trash = TrashRepository(database: database)
    }
}
