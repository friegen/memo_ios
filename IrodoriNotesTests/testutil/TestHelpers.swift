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

/// 時刻を固定する時計（UseCase のテスト用）。
final class FixedClock: AppClock, @unchecked Sendable {
    var nowValue: Int64

    init(_ now: Int64) {
        nowValue = now
    }

    override func now() -> Int64 { nowValue }
}

/// テストごとに別の保存先の UserDefaults（アプリの設定を汚さない）。
func makeTestDefaults() throws -> UserDefaults {
    let suiteName = "IrodoriNotesTests-\(UUID().uuidString)"
    let defaults = try #require(UserDefaults(suiteName: suiteName))
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}

/// テスト用の入れ物（メモリ上の DB・別の保存先の UserDefaults・固定の時計）。
func makeTestContainer(now: Int64 = 0) throws -> (container: AppContainer, defaults: UserDefaults, clock: FixedClock) {
    let defaults = try makeTestDefaults()
    let clock = FixedClock(now)
    let container = AppContainer(database: try AppDatabase.makeInMemory(), defaults: defaults, clock: clock)
    return (container, defaults, clock)
}
