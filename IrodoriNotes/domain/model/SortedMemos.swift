import Foundation

/// 並び替え済みのメモ一覧と、そのときの並び順（並び替えメニューで今の選択を示すのに使う）。
nonisolated struct SortedMemos: Equatable, Sendable {
    let sort: MemoSort
    let memos: [MemoSummary]
}
