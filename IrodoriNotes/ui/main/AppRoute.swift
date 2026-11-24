import Foundation

/// タブの中で積み重ねて開く画面（Android の Navigation の行き先・Intent にあたる）。
enum AppRoute: Hashable {
    /// メモの編集画面。memoId が nil なら新規作成。folderId が nil ならメモタブのメモ
    case editor(memoId: Int64?, folderId: Int64?)
    /// フォルダの中
    case folder(folderId: Int64)
    /// 設定の「表示」（文字の大きさ・行間）
    case displaySettings
    /// 設定の「データ」（データサイズ・バックアップ）
    case dataSettings
    /// ゴミ箱
    case trash
    /// オープンソースライセンスの一覧
    case licenses
    /// ライセンスの全文
    case license(OssLibrary)
}
