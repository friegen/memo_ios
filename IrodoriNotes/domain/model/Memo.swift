import Foundation

/// メモに関する決まりごと（Android 版の MemoPolicy と同じ値）。
nonisolated enum MemoPolicy {
    /// 1メモの文字数の上限（改行を除いた書記素単位。`CharCounter` と同じ数え方）。編集画面で入力を止める。
    static let maxChars = 100_000

    /// 一覧用に保存する1行目の最大文字数。横向きでも1行に収まらない長さで十分。
    static let firstLineMaxChars = 50
}

/// メモ（本文を含む）。編集画面で使う。
///
/// 一覧では本文を読まない `MemoSummary` を使うこと（長いメモがあっても一覧が重くならないように）。
nonisolated struct Memo: Equatable, Sendable {
    let id: Int64
    /// 所属フォルダ。nil はメモタブのメモ（フォルダ内のメモとは別物）
    let folderId: Int64?
    /// 装飾付きの本文（HTML）
    let html: String
    /// 装飾なしの本文
    let plainText: String
    /// 改行を除いた書記素単位の文字数
    let charCount: Int
    let createdAt: Int64
    let updatedAt: Int64
    /// このメモ自体をロックしているか（開くたびに端末の認証が必要）
    var isLocked: Bool = false
    /// ロックしている上の階層のフォルダ（中に入るときに認証済みなら、もう一度は聞かない）
    var lockedFolderIds: [Int64] = []

    /// 開くときに守る必要があるか（このメモか上の階層がロックされている）。
    var isProtected: Bool { isLocked || !lockedFolderIds.isEmpty }
}

/// 一覧用のメモ（本文は持たない）。
nonisolated struct MemoSummary: Equatable, Sendable, Identifiable {
    let id: Int64
    let folderId: Int64?
    /// 一覧に表示する1行目（保存時に作る。`MemoPolicy.firstLineMaxChars` 文字まで）
    let firstLine: String
    let charCount: Int
    let createdAt: Int64
    var updatedAt: Int64
    /// ロックしているか（一覧ではロックのアイコンを付ける）
    var isLocked: Bool = false
    /// ピン留めしているか（並び順にかかわらず一番上に出し、ピンのアイコンを付ける）
    var isPinned: Bool = false

    /// 作成後に内容が更新されているか（一覧で「更新日」を出すかの判定に使う）。
    var isUpdated: Bool { updatedAt != createdAt }
}
