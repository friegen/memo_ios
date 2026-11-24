import SafariServices
import UIKit

/// アプリ内のブラウザ（SFSafariViewController。Android の Chrome Custom Tabs にあたる）でページを開く。
/// Safari と同じ画面がアプリの上に出て、「完了」でアプリに戻る。
enum InAppBrowser {

    static func open(_ url: URL) {
        guard let presenter = TopViewController.current() else {
            AppLog.error("ブラウザを出す画面が見つからない")
            return
        }
        presenter.present(SFSafariViewController(url: url), animated: true)
    }
}

/// 出力したファイルを共有シート（Android の共有の画面にあたる）で渡す。複数のファイル（長いメモの画像）はまとめて渡す。
/// 共有シートから「ファイルに保存」「プリント」なども選べる。
enum ShareSheet {

    static func present(_ files: [URL]) {
        guard let presenter = TopViewController.current() else {
            AppLog.error("共有シートを出す画面が見つからない")
            return
        }
        let controller = UIActivityViewController(activityItems: files, applicationActivities: nil)
        // iPad で iPhone 版が動くときに備えて、出す位置を決めておく（iPhone では使われない）
        controller.popoverPresentationController?.sourceView = presenter.view
        controller.popoverPresentationController?.sourceRect = CGRect(
            x: presenter.view.bounds.midX, y: presenter.view.bounds.midY, width: 0, height: 0)
        presenter.present(controller, animated: true)
    }
}

/// 今いちばん上に出ている画面（シートなどが出ていればその画面）。UIKit の画面（ブラウザ・共有シート）を上に出すのに使う。
enum TopViewController {

    static func current() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        let scene = scenes.first { $0.activationState == .foregroundActive } ?? scenes.first
        guard var top = scene?.keyWindow?.rootViewController else { return nil }
        while let presented = top.presentedViewController {
            top = presented
        }
        return top
    }
}
