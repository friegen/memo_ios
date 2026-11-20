import Foundation

/// メモで使える装飾（色以外）。Android 版の MemoTextStyle と同じ。
nonisolated enum MemoTextStyle: CaseIterable, Sendable {
    case bold, italic, underline

    /// 本文に付ける「この装飾が付いている」という印（意味の情報）。保存（HTML）はこの印から作る。
    var attributeKey: NSAttributedString.Key {
        switch self {
        case .bold: .memoBold
        case .italic: .memoItalic
        case .underline: .memoUnderline
        }
    }
}

nonisolated extension NSAttributedString.Key {
    /// 太字の印（Bool）。見た目（フォント）は `MemoTextAttributes` が付ける
    static let memoBold = NSAttributedString.Key("xyz.friegen.memo.bold")
    /// 斜体の印（Bool）
    static let memoItalic = NSAttributedString.Key("xyz.friegen.memo.italic")
    /// 下線の印（Bool）
    static let memoUnderline = NSAttributedString.Key("xyz.friegen.memo.underline")
    /// 文字色の名前（String。red など）。表示する色はライト／ダークで変わるので、名前を持つ
    static let memoColor = NSAttributedString.Key("xyz.friegen.memo.color")
}

/// 文字の書式（太字・斜体・下線・文字色）。Android 版の TextFormat と同じ。
/// 書式パネルに表示する状態と、パネルを開いているときに「これから入力する文字」に付ける書式に使う。
nonisolated struct TextFormat: Equatable, Sendable {
    var bold = false
    var italic = false
    var underline = false
    /// 文字色の名前（red など）。nil は既定の色
    var colorKey: String?

    /// 書式なし。
    static let none = TextFormat()

    func has(_ style: MemoTextStyle) -> Bool {
        switch style {
        case .bold: bold
        case .italic: italic
        case .underline: underline
        }
    }

    func with(_ style: MemoTextStyle, _ enabled: Bool) -> TextFormat {
        var copy = self
        switch style {
        case .bold: copy.bold = enabled
        case .italic: copy.italic = enabled
        case .underline: copy.underline = enabled
        }
        return copy
    }

    /// 本文に付ける意味の情報（印）。
    var semanticAttributes: [NSAttributedString.Key: Any] {
        var attributes: [NSAttributedString.Key: Any] = [:]
        if bold { attributes[.memoBold] = true }
        if italic { attributes[.memoItalic] = true }
        if underline { attributes[.memoUnderline] = true }
        if let colorKey { attributes[.memoColor] = colorKey }
        return attributes
    }

    /// 本文の1文字分の印から書式を読む。
    init(attributes: [NSAttributedString.Key: Any]) {
        bold = attributes[.memoBold] as? Bool == true
        italic = attributes[.memoItalic] as? Bool == true
        underline = attributes[.memoUnderline] as? Bool == true
        colorKey = attributes[.memoColor] as? String
    }

    init(bold: Bool = false, italic: Bool = false, underline: Bool = false, colorKey: String? = nil) {
        self.bold = bold
        self.italic = italic
        self.underline = underline
        self.colorKey = colorKey
    }
}

/// メモの文字色（10色）。rawValue は保存する名前（HTML の `<font color="...">` に入る。Android と同じ）。
/// CSS の色名と同じなので、将来書き出したときも色として読める。表示する色はライト／ダークで変える（Assets の MemoTextXxx）。
nonisolated enum MemoTextColor: String, CaseIterable, Sendable {
    case red, orange, yellow, green, teal, blue, purple, pink, brown, gray

    /// Assets.xcassets の色の名前
    var assetName: String { "MemoText" + rawValue.prefix(1).uppercased() + rawValue.dropFirst() }

    /// 色の名前の訳のキー（color_red など）
    var nameKey: String { "color_" + rawValue }
}
