import Foundation
import GRDB

/// フォルダのテーブル（folders）の1行。Android 版の FolderEntity にあたる。
nonisolated struct FolderRecord: Codable, Sendable, FetchableRecord, MutablePersistableRecord {
    static let databaseTableName = "folders"

    /// 保存前は nil
    var id: Int64?
    /// 親フォルダ。nil はフォルダタブ直下
    var parentId: Int64?
    var name: String
    /// `FolderColor` の rawValue
    var colorKey: String
    var createdAt: Int64
    /// 中身の追加・編集・削除・移動で、上の階層まですべて更新する（名前・色の変更では更新しない）
    var updatedAt: Int64
    /// ゴミ箱に入れた時刻。nil なら有効
    var deletedAt: Int64? = nil
    /// 上のフォルダの削除に巻き込まれてゴミ箱に入ったか（単体で削除したフォルダと区別する）
    var deletedWithParent: Bool = false
    /// ロックしているか（中のフォルダ・メモも全階層まとめて守られる）
    var isLocked: Bool = false
    var isPinned: Bool = false

    mutating func didInsert(_ inserted: InsertionSuccess) {
        id = inserted.rowID
    }

    /// 保存済みのレコードの id。
    var savedId: Int64 {
        guard let id else { preconditionFailure("保存前のフォルダ") }
        return id
    }
}

/// フォルダ＋直下の（ゴミ箱に入っていない）メモ数＋フォルダ数。
nonisolated struct FolderWithItemCountRow: Sendable {
    let folder: FolderRecord
    let itemCount: Int
}

/// フォルダごとの件数（ゴミ箱で「一緒に削除されたメモ」を数えるのに使う）。
nonisolated struct FolderIdCountRow: Decodable, Sendable, FetchableRecord {
    let folderId: Int64
    let count: Int
}
