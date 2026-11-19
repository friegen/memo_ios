import SwiftUI
import UIKit

extension ThemeMode {
    /// iOS の画面の明るさの設定（Android の AppCompatDelegate.setDefaultNightMode にあたる）。
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: .unspecified
        case .light: .light
        case .dark: .dark
        }
    }
}

/// アプリのウィンドウにテーマ（ライト／ダーク／端末に従う）を反映する。
///
/// SwiftUI の `.preferredColorScheme` は「端末に従う」に戻したときに前のテーマが残ることがあるので、
/// ウィンドウの設定（`overrideUserInterfaceStyle`）を直接変える。シート・アラート・UIKit の部品にも反映される。
struct WindowThemeApplier: UIViewRepresentable {
    let mode: ThemeMode

    func makeUIView(context: Context) -> ApplierView {
        ApplierView()
    }

    func updateUIView(_ view: ApplierView, context: Context) {
        view.style = mode.userInterfaceStyle
    }

    final class ApplierView: UIView {
        var style: UIUserInterfaceStyle = .unspecified {
            didSet { apply() }
        }

        override func didMoveToWindow() {
            super.didMoveToWindow()
            apply() // ウィンドウに付いたらすぐ（最初の画面を描く前に）反映する
        }

        private func apply() {
            window?.overrideUserInterfaceStyle = style
        }
    }
}
