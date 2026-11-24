import Foundation

/// アプリから開くページ（Android 版の config.xml の URL にあたる）。
nonisolated enum AppLinks {
    /// プライバシーポリシー（GitHub Pages の friegen.github.io の irodori-notes/privacy-policy.md。Android 版と同じページ）。
    /// 置き場所を変えたらここも変える
    static let privacyPolicy = URL(string: "https://friegen.github.io/irodori-notes/privacy-policy.html")!
}
