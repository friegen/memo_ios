import SafariServices
import UIKit

/// アプリ内のブラウザ（SFSafariViewController。Android の Chrome Custom Tabs にあたる）でページを開く。
/// Safari と同じ画面がアプリの上に出て、「完了」でアプリに戻る。
enum InAppBrowser {

    static func open(_ url: URL) {
        guard let presenter = topViewController() else {
            AppLog.error("ブラウザを出す画面が見つからない")
            return
        }
        presenter.present(SFSafariViewController(url: url), animated: true)
    }

    /// 今いちばん上に出ている画面（シートなどが出ていればその画面）。
    private static func topViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard var top = scene?.keyWindow?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
