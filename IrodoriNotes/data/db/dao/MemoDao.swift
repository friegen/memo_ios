import Foundation
import GRDB

/// メモのテーブルを読み書きする SQL（Android 版の MemoDao にあたる）。
/// 一覧系はゴミ箱のものを必ず除き、本文（html / plainText）は読まない。
nonisolated enum MemoDao {

    /// 一覧用に読む列（本文 html / plainText は含めない）。`MemoSummaryRow` と対応させる。
    static let summaryColumns = "id, folderId, firstLine, charCount, createdAt, updatedAt, deletedAt, isLocked, isPinned"

    // MARK: 一覧

    /// メモタブのメモ。
    static func memoTabMemos(_ db: Database) throws -> [MemoSummaryRow] {
        try MemoSummaryRow.fetchAll(
            db, sql: "SELECT \(summaryColumns) FROM memos WHERE folderId IS NULL AND deletedAt IS NULL")
    }

    /// フォルダ内のメモ。
    static func folderMemos(_ db: Database, folderId: Int64) throws -> [MemoSummaryRow] {
        try MemoSummaryRow.fetchAll(
            db, sql: "SELECT \(summaryColumns) FROM memos WHERE folderId = ? AND deletedAt IS NULL", arguments: [folderId])
    }

    /// 本文を含めて1件読む（編集画面用）。
    static func findById(_ db: Database, id: Int64) throws -> MemoRecord? {
        try MemoRecord.fetchOne(db, key: id)
    }

    /// 本文を読まずに1件読む（ゴミ箱やフォルダの更新日の判定など、本文が要らない処理用）。
    static func findSummaryById(_ db: Database, id: Int64) throws -> MemoSummaryRow? {
        try MemoSummaryRow.fetchOne(db, sql: "SELECT \(summaryColumns) FROM memos WHERE id = ?", arguments: [id])
    }

    // MARK: 作成・更新

    /// - Returns: 作ったメモの id
    static func insert(_ db: Database, _ memo: MemoRecord) throws -> Int64 {
        var memo = memo
        try memo.insert(db)
        return memo.savedId
    }

    static func updateContent(
        _ db: Database, id: Int64, html: String, plainText: String, firstLine: String, charCount: Int, updatedAt: Int64
    ) throws {
        try db.execute(
            sql: """
                UPDATE memos SET html = ?, plainText = ?, firstLine = ?, charCount = ?, updatedAt = ?
                WHERE id = ?
                """,
            arguments: [html, plainText, firstLine, charCount, updatedAt, id])
    }

    /// ロックの付け外し（更新日は変えない）。
    static func setLocked(_ db: Database, id: Int64, locked: Bool) throws {
        try db.execute(sql: "UPDATE memos SET isLocked = ? WHERE id = ?", arguments: [locked, id])
    }

    /// ピン留め（更新日は変えない）。
    static func setPinned(_ db: Database, id: Int64, pinned: Bool) throws {
        try db.execute(sql: "UPDATE memos SET isPinned = ? WHERE id = ?", arguments: [pinned, id])
    }

    /// 移動ではメモ自体の更新日は変えない（内容は変わっていないため）。
    static func moveToFolder(_ db: Database, ids: [Int64], folderId: Int64) throws {
        guard !ids.isEmpty else { return }
        try db.execute(literal: "UPDATE memos SET folderId = \(folderId) WHERE id IN \(ids)")
    }

    // MARK: ゴミ箱

    /// 単体でゴミ箱へ。
    static func moveToTrash(_ db: Database, id: Int64, deletedAt: Int64) throws {
        try db.execute(
            sql: "UPDATE memos SET deletedAt = ?, deletedWithFolder = 0 WHERE id = ?", arguments: [deletedAt, id])
    }

    /// フォルダの削除に合わせて、そのフォルダ（と中のフォルダ）の有効なメモをゴミ箱へ。
    static func moveToTrashWithFolder(_ db: Database, folderIds: [Int64], deletedAt: Int64) throws {
        guard !folderIds.isEmpty else { return }
        try db.execute(literal: """
            UPDATE memos SET deletedAt = \(deletedAt), deletedWithFolder = 1
            WHERE folderId IN \(folderIds) AND deletedAt IS NULL
            """)
    }

    static func restore(_ db: Database, id: Int64) throws {
        try db.execute(sql: "UPDATE memos SET deletedAt = NULL, deletedWithFolder = 0 WHERE id = ?", arguments: [id])
    }

    /// フォルダと一緒に削除されたメモを戻す（先に単体で削除したメモは戻さない）。
    static func restoreDeletedWithFolder(_ db: Database, folderIds: [Int64]) throws {
        guard !folderIds.isEmpty else { return }
        try db.execute(literal: """
            UPDATE memos SET deletedAt = NULL, deletedWithFolder = 0
            WHERE folderId IN \(folderIds) AND deletedWithFolder = 1
            """)
    }

    /// ゴミ箱に単体で入っているメモ。フォルダごと削除されたメモはフォルダ側の項目にまとめるので含めない。
    static func trashedMemos(_ db: Database) throws -> [MemoSummaryRow] {
        try MemoSummaryRow.fetchAll(
            db, sql: "SELECT \(summaryColumns) FROM memos WHERE deletedAt IS NOT NULL AND deletedWithFolder = 0")
    }

    /// フォルダごとの「フォルダと一緒に削除されたメモ」の件数。
    static func deletedWithFolderCounts(_ db: Database) throws -> [FolderIdCountRow] {
        try FolderIdCountRow.fetchAll(db, sql: """
            SELECT folderId, COUNT(*) AS count FROM memos
            WHERE deletedAt IS NOT NULL AND deletedWithFolder = 1 AND folderId IS NOT NULL
            GROUP BY folderId
            """)
    }

    /// 指定したフォルダに入っている有効なメモの件数（削除の確認ダイアログ用）。
    static func countActiveInFolders(_ db: Database, folderIds: [Int64]) throws -> Int {
        guard !folderIds.isEmpty else { return 0 }
        return try SQLRequest<Int>(literal: "SELECT COUNT(*) FROM memos WHERE folderId IN \(folderIds) AND deletedAt IS NULL").fetchOne(db) ?? 0
    }

    /// 指定したフォルダに入っているメモの件数（ゴミ箱のものも含む。完全削除の確認ダイアログ用）。
    static func countInFolders(_ db: Database, folderIds: [Int64]) throws -> Int {
        guard !folderIds.isEmpty else { return 0 }
        return try SQLRequest<Int>(literal: "SELECT COUNT(*) FROM memos WHERE folderId IN \(folderIds)").fetchOne(db) ?? 0
    }

    static func deletePermanently(_ db: Database, id: Int64) throws {
        try db.execute(sql: "DELETE FROM memos WHERE id = ?", arguments: [id])
    }

    /// ゴミ箱に単体で入っているメモをすべて完全削除。
    static func deleteAllTrashed(_ db: Database) throws {
        try db.execute(sql: "DELETE FROM memos WHERE deletedAt IS NOT NULL AND deletedWithFolder = 0")
    }

    /// 期限切れ（threshold より前に削除）の単体削除メモを完全削除。
    static func deleteExpired(_ db: Database, threshold: Int64) throws {
        try db.execute(sql: "DELETE FROM memos WHERE deletedAt < ? AND deletedWithFolder = 0", arguments: [threshold])
    }
}
