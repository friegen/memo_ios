import Foundation
import GRDB

/// メモのテーブル（memos）の1行。Android 版の MemoEntity にあたる。画面側には出さない（Repository でドメインモデルに変える）。
nonisolated struct MemoRecord: Codable, Sendable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "memos"

    /// 保存前は nil
    var id: Int64?
    /// 所属フォルダ。nil はメモタブのメモ
    var folderId: Int64?
    /// 装飾付きの本文
    var html: String
    /// 装飾なしの本文（文字数の計算などに使う）
    var plainText: String
    /// 一覧用の1行目（保存時に plainText から作る）。一覧では本文を読まずにこの列だけを読む
    var firstLine: String
    var charCount: Int
    var createdAt: Int64
    var updatedAt: Int64
    /// ゴミ箱に入れた時刻。nil なら有効
    var deletedAt: Int64? = nil
    /// フォルダの削除に巻き込まれてゴミ箱に入ったか（単体で削除したメモと区別する）
    var deletedWithFolder: Bool = false
    var isLocked: Bool = false
    var isPinned: Bool = false

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    /// 保存済みのレコードの id。
    var savedId: Int64 {
        guard let id else { preconditionFailure("保存前のメモ") }
        return id
    }
}

/// 一覧用のメモ（本文 html / plainText は読まない）。`MemoDao.summaryColumns` と対応させる。
nonisolated struct MemoSummaryRow: Decodable, Sendable, FetchableRecord {
    let id: Int64
    let folderId: Int64?
    let firstLine: String
    let charCount: Int
    let createdAt: Int64
    let updatedAt: Int64
    let deletedAt: Int64?
    let isLocked: Bool
    let isPinned: Bool
}
