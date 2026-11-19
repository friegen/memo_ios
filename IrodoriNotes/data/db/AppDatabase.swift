import Foundation
import GRDB

/// アプリの DB（GRDB / SQLite）。Android 版の AppDatabase（Room）にあたる。
///
/// テーブル・列は Android 版と同じにしている（将来バックアップを Android と共通にしやすくするため）。
/// スキーマを変えるときは `migrator` に新しいマイグレーションを足す（`eraseDatabaseOnSchemaChange` は使わない。メモが消えるため）。
/// ただし未リリースの間は、最初のマイグレーション（"v1"）を書き換えてよい（確認するときはシミュレーターのアプリを消してから）。
nonisolated final class AppDatabase: Sendable {

    /// DB のファイル名（`Library/Application Support/` の下）。データサイズの表示でも使う。
    static let fileName = "memo.sqlite"

    /// 読み書きの入り口。トランザクションは `writer.write { db in ... }`（Room の withWriteTransaction にあたる）。
    let writer: any DatabaseWriter

    init(_ writer: any DatabaseWriter) throws {
        self.writer = writer
        try Self.migrator.migrate(writer)
    }

    /// アプリで使う DB（ファイル）。
    static func makeDefault() throws -> AppDatabase {
        let directory = try FileManager.default.url(
            for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let pool = try DatabasePool(path: directory.appendingPathComponent(fileName).path)
        return try AppDatabase(pool)
    }

    /// テスト用のメモリ上の DB。
    static func makeInMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    /// DB の中身が変わるたびに `fetch` の結果を流す（Android の Room の Flow にあたる）。
    /// 最初に今の値を1回流す。
    func observe<T: Sendable>(_ fetch: @escaping @Sendable (Database) throws -> T) -> AsyncThrowingStream<T, any Error> {
        let writer = self.writer
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await value in ValueObservation.tracking(fetch).values(in: writer) {
                        continuation.yield(value)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()
        migrator.registerMigration("v1") { db in
            // フォルダ。親（parentId）を完全削除すると、中のフォルダも CASCADE で完全削除される
            try db.create(table: "folders") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("parent", inTable: "folders", onDelete: .cascade) // 列名は parentId（索引も作られる）
                t.column("name", .text).notNull()
                t.column("colorKey", .text).notNull()
                t.column("createdAt", .integer).notNull()
                t.column("updatedAt", .integer).notNull()
                t.column("deletedAt", .integer)
                t.column("deletedWithParent", .boolean).notNull().defaults(to: false)
                t.column("isLocked", .boolean).notNull().defaults(to: false)
                t.column("isPinned", .boolean).notNull().defaults(to: false)
            }
            // メモ。フォルダ（folderId）を完全削除すると、そのフォルダのメモも CASCADE で完全削除される
            try db.create(table: "memos") { t in
                t.autoIncrementedPrimaryKey("id")
                t.belongsTo("folder", inTable: "folders", onDelete: .cascade) // 列名は folderId（索引も作られる）
                t.column("html", .text).notNull()
                t.column("plainText", .text).notNull()
                t.column("firstLine", .text).notNull()
                t.column("charCount", .integer).notNull()
                t.column("createdAt", .integer).notNull()
                t.column("updatedAt", .integer).notNull()
                t.column("deletedAt", .integer)
                t.column("deletedWithFolder", .boolean).notNull().defaults(to: false)
                t.column("isLocked", .boolean).notNull().defaults(to: false)
                t.column("isPinned", .boolean).notNull().defaults(to: false)
            }
        }
        return migrator
    }
}
