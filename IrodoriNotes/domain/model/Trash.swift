import Foundation

/// ゴミ箱の保持期間。これを過ぎたものはアプリ起動時に完全削除する。
nonisolated enum TrashPolicy {
    static let retentionDays: Int64 = 30
    static let retentionMillis: Int64 = retentionDays * 24 * 60 * 60 * 1000

    /// この時刻より前に削除されたものが期限切れ。
    static func expiryThreshold(now: Int64) -> Int64 { now - retentionMillis }
}

/// ゴミ箱の1項目。
nonisolated enum TrashItem: Equatable, Sendable {
    case memo(TrashedMemo)
    case folder(TrashedFolder)

    var deletedAt: Int64 {
        switch self {
        case .memo(let item): item.deletedAt
        case .folder(let item): item.deletedAt
        }
    }
}

/// 単体で削除されたメモ。
nonisolated struct TrashedMemo: Equatable, Sendable {
    let memo: MemoSummary
    /// 元のフォルダ名。メモタブのメモは nil
    let folderName: String?
    /// 元のフォルダか、その上の階層のどこかがゴミ箱にあるか（復元時に「フォルダごと復元」の確認が必要）
    let isFolderInTrash: Bool
    let deletedAt: Int64
    /// このメモか上の階層がロックされている（鍵のアイコンを付ける）
    var isLocked: Bool = false
}

/// 削除されたフォルダ（一番上のフォルダだけを1項目にする。一緒に削除された中身は含めて数える）。
nonisolated struct TrashedFolder: Equatable, Sendable {
    let folder: Folder
    /// 一緒に削除された中のフォルダの数（全階層）
    let folderCount: Int
    /// 一緒に削除されたメモの数（全階層）
    let memoCount: Int
    /// 親フォルダ名。フォルダタブ直下なら nil
    let parentName: String?
    /// 上の階層のどこかがゴミ箱にあるか（復元時に「フォルダごと復元」の確認が必要）
    let isParentInTrash: Bool
    let deletedAt: Int64
    /// このフォルダか上の階層がロックされている（ロックのアイコンを付ける）
    var isLocked: Bool = false
}
