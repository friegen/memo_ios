import UIKit

/// メモの本文の見た目（フォント・行間・下線・文字色）。本文の意味の情報（`.memoBold` などの印）から作る。
///
/// - 太字: 太字のフォント
/// - 斜体: 文字を傾ける（`.obliqueness`）。日本語のフォントには斜体がないので、Android と同じく傾けて見せる
/// - 文字色: Assets の MemoTextXxx（ライト／ダークで自動で変わる）
/// 編集画面と、設定の「表示」画面のサンプル、出力（PDF・画像）で同じ見た目にするため共通にしている。
enum MemoTextAttributes {

    /// 文字色の名前から表示する色。知らない名前なら nil。
    typealias Palette = (String) -> UIColor?

    /// ライト／ダークで自動で変わる色（画面に出すとき）。
    static let dynamicPalette: Palette = { key in
        MemoTextColor(rawValue: key).flatMap { UIColor(named: $0.assetName) }
    }

    /// 書式の見た目＋意味の情報（入力する文字の typingAttributes にも使う）。
    static func attributes(
        for format: TextFormat, settings: EditorSettings, palette: Palette = dynamicPalette,
        defaultColor: UIColor = .label
    ) -> [NSAttributedString.Key: Any] {
        var attributes = format.semanticAttributes
        attributes[.font] = font(settings: settings, bold: format.bold)
        attributes[.paragraphStyle] = paragraphStyle(settings: settings)
        attributes[.foregroundColor] = format.colorKey.flatMap(palette) ?? defaultColor
        if format.italic { attributes[.obliqueness] = 0.2 }
        if format.underline { attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue }
        return attributes
    }

    /// 本文の範囲の見た目を、意味の情報に合わせて付け直す（読み込み・書式の変更・文字の大きさの変更のとき）。
    static func applyVisuals(
        to text: NSMutableAttributedString, range: NSRange? = nil, settings: EditorSettings,
        palette: Palette = dynamicPalette, defaultColor: UIColor = .label
    ) {
        let range = range ?? NSRange(location: 0, length: text.length)
        guard range.length > 0 else { return }
        text.beginEditing()
        text.enumerateAttributes(in: range) { current, subrange, _ in
            let format = TextFormat(attributes: current)
            text.removeAttribute(.obliqueness, range: subrange)
            text.removeAttribute(.underlineStyle, range: subrange)
            text.addAttributes(attributes(for: format, settings: settings, palette: palette, defaultColor: defaultColor), range: subrange)
        }
        text.endEditing()
    }

    /// 文字の大きさ（Android の sp と同じく、端末の文字の大きさの設定にも合わせる）。
    static func font(settings: EditorSettings, bold: Bool) -> UIFont {
        let base = UIFont.systemFont(ofSize: settings.fontSize.sizePt, weight: bold ? .bold : .regular)
        return UIFontMetrics(forTextStyle: .body).scaledFont(for: base)
    }

    static func paragraphStyle(settings: EditorSettings) -> NSParagraphStyle {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = settings.lineSpacing.multiplier
        return paragraph
    }
}
