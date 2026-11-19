import SwiftUI

/// アプリの入り口（Android の Application ＋ MainActivity にあたる）。
@main
struct IrodoriNotesApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}

/// テストからアプリの Bundle を見つけるための目印（中身はない）。
final class BundleToken {}
