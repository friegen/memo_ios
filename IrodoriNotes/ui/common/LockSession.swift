import Foundation
import Observation

/// ロックを外している状態（docs/requirements.md「ロック」）。アプリで1つだけ持つ（Android 版の LockSession にあたる）。
///
/// - ロックしたフォルダは、中に入るときに認証して外す。そのフォルダの画面を閉じる（上の階層に戻る）とまたロックする
/// - ロックしたメモは、開くたびに認証する（ここでは覚えない。画面が `generation` を覚える）
/// - アプリから離れたら（バックグラウンドへ）すべてロックし直す。`generation` が増えるので、
///   開いているロックの画面は中身を隠して、戻ってきたときにもう一度認証する
/// - 認証している間（Face ID・パスコードの画面）は「アプリから離れた」扱いにしない
@Observable
final class LockSession {
    /// アプリから離れてロックし直すたびに増える。
    private(set) var generation = 0

    /// ロックした中身を表示している画面の数。1つ以上あれば、アプリの切り替え画面に中身を映さない（Android の FLAG_SECURE にあたる）
    private(set) var protectedScreenCount = 0

    /// 認証の画面を出している間は true（このときはアプリの切り替え画面用の覆いも出さない）。
    var isAuthenticating = false

    /// ロックを外したフォルダ（変わると、そのフォルダの画面が中身を見せる）
    private var unlockedFolders: Set<Int64> = []

    /// アプリがバックグラウンドに回った。
    func onEnterBackground() {
        if !isAuthenticating { lockAll() }
    }

    /// すべてロックし直す。
    func lockAll() {
        unlockedFolders.removeAll()
        generation += 1
    }

    func unlockFolders(_ folderIds: [Int64]) {
        unlockedFolders.formUnion(folderIds)
    }

    /// フォルダの画面を閉じた（上の階層に戻った）ので、またロックする。
    func lockFolder(_ folderId: Int64) {
        unlockedFolders.remove(folderId)
    }

    /// `folderIds` がすべてロックを外してあるか（空なら true）。
    func areUnlocked(_ folderIds: [Int64]) -> Bool {
        unlockedFolders.isSuperset(of: folderIds)
    }

    /// ロックした中身を表示する画面が出た／閉じた。
    func acquireProtectedScreen() { protectedScreenCount += 1 }

    func releaseProtectedScreen() { protectedScreenCount = max(0, protectedScreenCount - 1) }
}
