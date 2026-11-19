import Foundation

/// フォルダの階層（木構造）をたどるための補助。全フォルダ（ゴミ箱のものも含む）から作る。
///
/// フォルダの数はメモより十分少ないので、SQL の再帰クエリではなく全件を読んで Swift でたどる
/// （読みやすく、テストもしやすいため。Android 版と同じ）。
nonisolated struct FolderTree: Sendable {

    private let byId: [Int64: FolderRecord]
    private let childrenByParent: [Int64?: [FolderRecord]]

    init(_ folders: [FolderRecord]) {
        byId = Dictionary(folders.map { ($0.savedId, $0) }, uniquingKeysWith: { first, _ in first })
        childrenByParent = Dictionary(grouping: folders, by: \.parentId)
    }

    subscript(id: Int64) -> FolderRecord? { byId[id] }

    /// 自分を先頭に、親、その親…とフォルダタブ直下までたどった列。
    func chainOf(_ id: Int64) -> [FolderRecord] {
        var chain: [FolderRecord] = []
        var visited: Set<Int64> = [] // 念のため循環を防ぐ
        var current = byId[id]
        while let folder = current, visited.insert(folder.savedId).inserted {
            chain.append(folder)
            current = folder.parentId.flatMap { byId[$0] }
        }
        return chain
    }

    /// 階層の深さ。フォルダタブ直下が 1。
    func depthOf(_ id: Int64) -> Int { chainOf(id).count }

    /// 中のフォルダを全階層たどる（自分は含まない）。
    /// - Parameter descendInto: このフォルダの中まで降りるか（例: ゴミ箱で「一緒に削除されたもの」だけをたどる）
    func descendantsOf(_ id: Int64, descendInto: (FolderRecord) -> Bool = { _ in true }) -> [FolderRecord] {
        var result: [FolderRecord] = []
        var queue = childrenByParent[id] ?? []
        var index = 0
        while index < queue.count {
            let folder = queue[index]
            index += 1
            guard descendInto(folder) else { continue }
            result.append(folder)
            queue.append(contentsOf: childrenByParent[folder.savedId] ?? [])
        }
        return result
    }
}
