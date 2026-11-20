import Foundation

/// フォルダに関する決まりごと（Android 版の FolderPolicy と同じ値）。
nonisolated enum FolderPolicy {
    /// 階層の上限。フォルダタブ直下のフォルダが1階層目。この階層のフォルダの中にはフォルダを作れない。
    static let maxDepth = 5

    /// フォルダ名の最大文字数（入力欄で止める）。
    static let maxNameLength = 50
}

/// フォルダ。
nonisolated struct Folder: Equatable, Sendable, Identifiable {
    let id: Int64
    /// 親フォルダ。nil はフォルダタブ直下（1階層目）
    let parentId: Int64?
    let name: String
    let color: FolderColor
    let createdAt: Int64
    /// 中身（メモ・フォルダ）の追加・編集・削除・移動で、上の階層まですべて更新される。名前・色の変更では更新しない
    let updatedAt: Int64
    /// 直下の（ゴミ箱に入っていない）メモ数＋フォルダ数。中のフォルダの中身までは数えない
    let itemCount: Int
    /// ロックしているか（中に入るときに端末の認証が必要。一覧ではロックのアイコンを付ける）
    var isLocked: Bool = false
    /// ピン留めしているか（並び順にかかわらず一番上に出し、ピンのアイコンを付ける）
    var isPinned: Bool = false

    var isUpdated: Bool { updatedAt != createdAt }
}

/// フォルダの階層をたどったときの1段（ナビゲーションバーの「趣味 › 読書」表示や階層の深さの判定に使う）。
nonisolated struct FolderPathEntry: Equatable, Sendable {
    let id: Int64
    let name: String
    var isLocked: Bool = false
}

/// フォルダの木の1行（メモの移動先を選ぶ一覧用）。
nonisolated struct FolderTreeEntry: Equatable, Sendable, Identifiable {
    let id: Int64
    let name: String
    let color: FolderColor
    /// 階層の深さ。フォルダタブ直下が 1
    let depth: Int
}

/// フォルダの中身（全階層）の件数。削除の確認ダイアログに使う。
nonisolated struct FolderContents: Equatable, Sendable {
    let folderCount: Int
    let memoCount: Int
}

/// フォルダを作れなかったとき。
nonisolated enum FolderError: Error, Equatable {
    /// 親フォルダがすでに最大の階層にある（画面側で作れないようにしておくこと）
    case depthLimitReached
    /// 名前が空（画面側で決定できないようにしておくこと）
    case emptyName
}

/// フォルダの色。DB には `rawValue`（Android と同じ名前）を保存する。
/// 実際の色の値は画面側（Assets.xcassets）で名前に対応させる。
nonisolated enum FolderColor: String, CaseIterable, Sendable {
    case `default` = "default"
    case red, orange, yellow, green, teal, blue, indigo, purple, pink

    /// 保存している名前から色を決める。知らない名前・nil は既定の色。
    static func fromKey(_ key: String?) -> FolderColor {
        key.flatMap(FolderColor.init(rawValue:)) ?? .default
    }
}
