import SwiftUI
import UIKit

/// フォルダの色（ドメインの `FolderColor`）と、画面に出す色・名前の対応（Android 版の FolderColors.kt にあたる）。
/// 背景色はライト／ダークで変える（Assets の FolderXxx。ライトはパステル、ダークは落ち着いた色）。
extension FolderColor {
    /// 背景色（ライト／ダークで自動で変わる）。既定（色なし）は nil（画面の背景のまま）。
    var uiColor: UIColor? {
        self == .default ? nil : UIColor(named: "Folder" + rawValue.prefix(1).uppercased() + rawValue.dropFirst())
    }

    /// 色の名前（読み上げ用）の訳のキー。
    var nameKey: String {
        self == .default ? "folder_color_default" : "color_" + rawValue
    }
}

nonisolated enum FolderColors {
    /// 背景色の上で読める文字色。白と黒のうち、背景とのコントラスト比が高い方を選ぶ。
    /// （明るさが 0.5 を超えるかで決めると、ライトの赤のような中間の明るさで白を選んでしまい読みにくくなるため。Android と同じ）
    static func contentColor(on background: UIColor) -> UIColor {
        contrast(.black, background) >= contrast(.white, background) ? .black : .white
    }

    /// 2つの色のコントラスト比（WCAG。1〜21）。
    static func contrast(_ a: UIColor, _ b: UIColor) -> Double {
        let la = luminance(a), lb = luminance(b)
        return (max(la, lb) + 0.05) / (min(la, lb) + 0.05)
    }

    /// 相対輝度（WCAG）。
    static func luminance(_ color: UIColor) -> Double {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        func linear(_ c: CGFloat) -> Double {
            let c = Double(c)
            return c <= 0.03928 ? c / 12.92 : pow((c + 0.055) / 1.055, 2.4)
        }
        return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
    }
}

/// フォルダの中身の数の文言。「フォルダ2個、メモ5件」（0のものは省く。どちらも0なら空文字）。
/// フォルダ削除の確認とゴミ箱で共通に使う。
func folderContentsText(_ contents: FolderContents, bundle: Bundle = .main, locale: Locale? = nil) -> String {
    var parts: [String] = []
    if contents.folderCount > 0 {
        parts.append(L10n.format("folder_delete_folder_count", contents.folderCount, bundle: bundle, locale: locale))
    }
    if contents.memoCount > 0 {
        parts.append(L10n.format("folder_delete_memo_count", contents.memoCount, bundle: bundle, locale: locale))
    }
    return parts.joined(separator: L10n.string("list_separator", bundle: bundle))
}
