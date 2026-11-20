import Foundation

/// 並び替え済みのフォルダ一覧と、そのときの並び順（並び替えメニューで今の選択を示すのに使う）。
nonisolated struct SortedFolders: Equatable, Sendable {
    let sort: FolderSort
    let folders: [Folder]
}
