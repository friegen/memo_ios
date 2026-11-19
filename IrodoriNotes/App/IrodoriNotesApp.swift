import SwiftUI

/// アプリの入り口（Android 版の MemoApplication ＋ MainActivity にあたる）。
@main
struct IrodoriNotesApp: App {
    private let container: AppContainer

    init() {
        let container = AppContainer.makeDefault()
        self.container = container
        // 起動時に、ゴミ箱に入れてから30日たったものを完全削除する（Android の MemoApplication.onCreate と同じ）
        Task {
            do {
                try await container.makePurgeExpiredTrashUseCase()()
            } catch {
                AppLog.error("ゴミ箱の期限切れの削除に失敗: \(error)")
            }
        }
    }

    var body: some Scene {
        WindowGroup {
            MainView(container: container)
        }
    }
}

/// テストからアプリの Bundle を見つけるための目印（中身はない）。
final class BundleToken {}
