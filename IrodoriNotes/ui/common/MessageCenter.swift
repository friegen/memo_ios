import Observation

/// アプリ全体で1つのお知らせ（「ゴミ箱に移動しました［元に戻す］」など）の置き場。
/// 画面を閉じた後に前の画面に出したいお知らせ（例: 編集画面で削除 → 一覧に「ゴミ箱に移動しました」）もここに置く。
/// 各画面は `.undoBanner($messageCenter.item)` で表示する。
@Observable
final class MessageCenter {
    var item: UndoItem?

    /// お知らせを出す。同じ文言のお知らせがすでに出ていれば出し直さない（何度も入力して上限の案内が積み重ならないように）。
    func show(_ message: String, undo: (() -> Void)? = nil) {
        if undo == nil, item?.message == message { return }
        item = UndoItem(message: message, undo: undo)
    }
}
