import Foundation
import GRDB

/// フォルダのテーブルを読み書きする SQL（Android 版の FolderDao にあたる）。
/// 階層をたどる処理（上の階層・中の階層）は、全フォルダを読んで `FolderTree` で行う（フォルダの数はメモより十分少ないため）。
nonisolated enum FolderDao {

    /// 直下の有効なメモ数＋フォルダ数。`FolderWithItemCountRow.itemCount` と対応させる。
    private static let itemCount = """
        (SELECT COUNT(*) FROM memos m WHERE m.folderId = f.id AND m.deletedAt IS NULL)
        + (SELECT COUNT(*) FROM folders c WHERE c.parentId = f.id AND c.deletedAt IS NULL) AS itemCount
        """

    // MARK: 一覧（ゴミ箱のものは必ず除く）

    /// フォルダタブ直下の有効なフォルダ。
    static func rootFolders(_ db: Database) throws -> [FolderWithItemCountRow] {
        try withItemCount(db, sql: "SELECT f.*, \(itemCount) FROM folders f WHERE f.parentId IS NULL AND f.deletedAt IS NULL")
    }

    /// あるフォルダの直下の有効なフォルダ。
    static func childFolders(_ db: Database, parentId: Int64) throws -> [FolderWithItemCountRow] {
        try withItemCount(
            db, sql: "SELECT f.*, \(itemCount) FROM folders f WHERE f.parentId = ? AND f.deletedAt IS NULL",
            arguments: [parentId])
    }

    /// 1件（ゴミ箱のものも含む）。
    static func folderWithItemCount(_ db: Database, id: Int64) throws -> FolderWithItemCountRow? {
        try withItemCount(db, sql: "SELECT f.*, \(itemCount) FROM folders f WHERE f.id = ?", arguments: [id]).first
    }

    static func findById(_ db: Database, id: Int64) throws -> FolderRecord? {
        try FolderRecord.fetchOne(db, key: id)
    }

    /// 全フォルダ（ゴミ箱のものも含む）。階層をたどるのに使う。
    static func getAll(_ db: Database) throws -> [FolderRecord] {
        try FolderRecord.fetchAll(db, sql: "SELECT * FROM folders")
    }

    private static func withItemCount(
        _ db: Database, sql: String, arguments: StatementArguments = StatementArguments()
    ) throws -> [FolderWithItemCountRow] {
        try Row.fetchAll(db, sql: sql, arguments: arguments).map { row in
            FolderWithItemCountRow(folder: try FolderRecord(row: row), itemCount: row["itemCount"])
        }
    }

    // MARK: 作成・更新

    /// - Returns: 作ったフォルダの id
    static func insert(_ db: Database, _ folder: FolderRecord) throws -> Int64 {
        var folder = folder
        try folder.insert(db)
        return folder.savedId
    }

    /// 名前・色の変更。更新日は変えない。
    static func updateNameAndColor(_ db: Database, id: Int64, name: String, colorKey: String) throws {
        try db.execute(sql: "UPDATE folders SET name = ?, colorKey = ? WHERE id = ?", arguments: [name, colorKey, id])
    }

    /// ロックの付け外し（名前・色と同じく、更新日は変えない）。
    static func setLocked(_ db: Database, id: Int64, locked: Bool) throws {
        try db.execute(sql: "UPDATE folders SET isLocked = ? WHERE id = ?", arguments: [locked, id])
    }

    /// ピン留め（更新日は変えない）。
    static func setPinned(_ db: Database, id: Int64, pinned: Bool) throws {
        try db.execute(sql: "UPDATE folders SET isPinned = ? WHERE id = ?", arguments: [pinned, id])
    }

    /// 中身の変更があったフォルダの更新日を進める。上の階層もまとめて進めるときは `touchWithAncestors`。
    static func touch(_ db: Database, ids: [Int64], updatedAt: Int64) throws {
        guard !ids.isEmpty else { return }
        try db.execute(literal: "UPDATE folders SET updatedAt = \(updatedAt) WHERE id IN \(ids)")
    }

    /// 指定したフォルダと、その上の階層すべての更新日を進める（中身が変わったとき）。
    static func touchWithAncestors(_ db: Database, folderIds: some Collection<Int64>, now: Int64) throws {
        guard !folderIds.isEmpty else { return }
        let tree = FolderTree(try getAll(db))
        var ids: [Int64] = []
        for id in folderIds {
            for folder in tree.chainOf(id) where !ids.contains(folder.savedId) {
                ids.append(folder.savedId)
            }
        }
        try touch(db, ids: ids, updatedAt: now)
    }

    // MARK: ゴミ箱

    /// 単体でゴミ箱へ（削除の起点になったフォルダ）。
    static func moveToTrash(_ db: Database, id: Int64, deletedAt: Int64) throws {
        try db.execute(
            sql: "UPDATE folders SET deletedAt = ?, deletedWithParent = 0 WHERE id = ?", arguments: [deletedAt, id])
    }

    /// 上のフォルダの削除に合わせて、中の有効なフォルダをゴミ箱へ。
    static func moveToTrashWithParent(_ db: Database, ids: [Int64], deletedAt: Int64) throws {
        guard !ids.isEmpty else { return }
        try db.execute(literal: """
            UPDATE folders SET deletedAt = \(deletedAt), deletedWithParent = 1
            WHERE id IN \(ids) AND deletedAt IS NULL
            """)
    }

    static func restore(_ db: Database, ids: [Int64]) throws {
        guard !ids.isEmpty else { return }
        try db.execute(literal: "UPDATE folders SET deletedAt = NULL, deletedWithParent = 0 WHERE id IN \(ids)")
    }

    /// 完全削除。中のフォルダとメモは外部キーの CASCADE で一緒に消える。
    static func deletePermanently(_ db: Database, id: Int64) throws {
        try db.execute(sql: "DELETE FROM folders WHERE id = ?", arguments: [id])
    }

    static func deleteAllTrashed(_ db: Database) throws {
        try db.execute(sql: "DELETE FROM folders WHERE deletedAt IS NOT NULL")
    }

    /// 期限切れの、削除の起点になったフォルダを完全削除（中身は CASCADE で消える）。
    static func deleteExpired(_ db: Database, threshold: Int64) throws {
        try db.execute(sql: "DELETE FROM folders WHERE deletedAt < ? AND deletedWithParent = 0", arguments: [threshold])
    }
}
