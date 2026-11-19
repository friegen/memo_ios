import Foundation

/// メモ一覧（メモタブ / フォルダ内のメモ）の並び替え項目。rawValue は保存用（Android と同じ名前）。
nonisolated enum MemoSortKey: String, CaseIterable, Sendable {
    case createdAt = "CREATED_AT"
    case updatedAt = "UPDATED_AT"
    case charCount = "CHAR_COUNT"
}

/// フォルダ一覧（フォルダタブ・フォルダ内のフォルダ）の並び替え項目。itemCount は直下のメモ数＋フォルダ数。
nonisolated enum FolderSortKey: String, CaseIterable, Sendable {
    case createdAt = "CREATED_AT"
    case updatedAt = "UPDATED_AT"
    case name = "NAME"
    case itemCount = "ITEM_COUNT"
}

/// メモ一覧の並び順。既定は更新日の新しい順。
/// 同じ値どうしは id の大きい（新しく作った）順にして、表示順が毎回ぶれないようにする。
/// ピン留めしたものは、並び順にかかわらず一番上にまとめる（ピン留めしたものどうしは同じ並び順）。
nonisolated struct MemoSort: Equatable, Sendable {
    var key: MemoSortKey = .updatedAt
    var ascending: Bool = false

    func sort(_ memos: [MemoSummary]) -> [MemoSummary] {
        memos.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            let order: ComparisonResult = switch key {
            case .createdAt: compareValues(a.createdAt, b.createdAt)
            case .updatedAt: compareValues(a.updatedAt, b.updatedAt)
            case .charCount: compareValues(a.charCount, b.charCount)
            }
            if order != .orderedSame { return ascending ? order == .orderedAscending : order == .orderedDescending }
            return a.id > b.id
        }
    }
}

/// フォルダ一覧の並び順。既定は更新日の新しい順。
/// 名前順は端末の言語に合わせた比較を使う。ピン留めしたものは一番上にまとめる（メモと同じ）。
nonisolated struct FolderSort: Equatable, Sendable {
    var key: FolderSortKey = .updatedAt
    var ascending: Bool = false

    /// - Parameter locale: 名前順に使う言語（テストで指定できるように引数にしている）
    func sort(_ folders: [Folder], locale: Locale = .current) -> [Folder] {
        folders.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            let order: ComparisonResult = switch key {
            case .createdAt: compareValues(a.createdAt, b.createdAt)
            case .updatedAt: compareValues(a.updatedAt, b.updatedAt)
            case .name: compareNames(a.name, b.name, locale: locale)
            case .itemCount: compareValues(a.itemCount, b.itemCount)
            }
            if order != .orderedSame { return ascending ? order == .orderedAscending : order == .orderedDescending }
            return a.id > b.id
        }
    }
}

/// 名前を端末の言語の順で比べる（Android の Collator にあたる）。
nonisolated func compareNames(_ a: String, _ b: String, locale: Locale = .current) -> ComparisonResult {
    a.compare(b, options: [], range: nil, locale: locale)
}

private nonisolated func compareValues<T: Comparable>(_ a: T, _ b: T) -> ComparisonResult {
    a < b ? .orderedAscending : (a > b ? .orderedDescending : .orderedSame)
}
