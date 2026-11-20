import Foundation

/// 選んだ範囲に書式（太字・斜体・下線・文字色）を付けたり外したりする（Android 版の TextStyler にあたる）。
/// 本文の意味の情報（`.memoBold` などの印）だけを変える。見た目（フォント・色）は呼び出し側が `MemoTextAttributes` で付け直す。
///
/// - 太字などの切り替え: 範囲全体にすでに付いていれば外し、一部でも付いていなければ範囲全体に付ける（ワープロと同じ）
/// - 文字色: 範囲の色を置き換える。nil なら色を外して既定の色に戻す
/// - 範囲は UTF-16 の位置（UITextView と同じ数え方）
///
/// Android は装飾を「範囲（span）」で持つので、つなげる・分けるの処理が要ったが、
/// iOS は1文字ずつ印を持つので、範囲に印を付ける・外すだけでよい。
nonisolated enum TextStyler {

    /// 範囲の全文字に `style` が付いているか。
    static func hasStyle(_ text: NSAttributedString, _ range: NSRange, _ style: MemoTextStyle) -> Bool {
        guard range.length > 0 else { return false }
        var all = true
        text.enumerateAttribute(style.attributeKey, in: range) { value, _, stop in
            if value as? Bool != true {
                all = false
                stop.pointee = true
            }
        }
        return all
    }

    /// 範囲の `style` を切り替える。
    static func toggleStyle(_ text: NSMutableAttributedString, _ range: NSRange, _ style: MemoTextStyle) {
        guard range.length > 0 else { return }
        if hasStyle(text, range, style) {
            text.removeAttribute(style.attributeKey, range: range)
        } else {
            text.addAttribute(style.attributeKey, value: true, range: range)
        }
    }

    /// 範囲の文字色を `colorKey` にする。nil なら色を外す（既定の色）。
    static func setColor(_ text: NSMutableAttributedString, _ range: NSRange, _ colorKey: String?) {
        guard range.length > 0 else { return }
        if let colorKey {
            text.addAttribute(.memoColor, value: colorKey, range: range)
        } else {
            text.removeAttribute(.memoColor, range: range)
        }
    }

    /// 範囲の書式。選んだ範囲なら範囲全体に付いている書式（色は全体が同じ色のときだけ）、
    /// カーソルだけ（長さ0）ならカーソルの直前の1文字の書式（先頭なら書式なし）。
    static func formatOf(_ text: NSAttributedString, _ range: NSRange) -> TextFormat {
        if range.length == 0 {
            guard range.location > 0, range.location <= text.length else { return .none }
            // 直前の1文字（絵文字などは UTF-16 で2つ以上になるので、文字のまとまりで取る）
            let previous = (text.string as NSString).rangeOfComposedCharacterSequence(at: range.location - 1)
            return formatOf(text, previous)
        }
        return TextFormat(
            bold: hasStyle(text, range, .bold),
            italic: hasStyle(text, range, .italic),
            underline: hasStyle(text, range, .underline),
            colorKey: uniformColorKey(text, range))
    }

    /// 範囲をちょうど `format` の書式にする（付いていない装飾は付け、余計な装飾は外す）。
    static func applyFormat(_ text: NSMutableAttributedString, _ range: NSRange, _ format: TextFormat) {
        guard range.length > 0 else { return }
        for style in MemoTextStyle.allCases {
            if format.has(style) {
                text.addAttribute(style.attributeKey, value: true, range: range)
            } else {
                text.removeAttribute(style.attributeKey, range: range)
            }
        }
        setColor(text, range, format.colorKey)
    }

    /// 範囲の全文字が同じ色ならその色の名前。色なし（既定）や混在なら nil。
    static func uniformColorKey(_ text: NSAttributedString, _ range: NSRange) -> String? {
        guard range.length > 0 else { return nil }
        var key: String?
        var uniform = true
        var first = true
        text.enumerateAttribute(.memoColor, in: range) { value, _, stop in
            let current = value as? String
            if first {
                key = current
                first = false
            } else if current != key {
                uniform = false
                stop.pointee = true
            }
        }
        return uniform ? key : nil
    }

    /// 範囲のどこかに色が付いているか（書式パネルで「色が混ざっている」を見分けるのに使う）。
    static func hasAnyColor(_ text: NSAttributedString, _ range: NSRange) -> Bool {
        guard range.length > 0 else { return false }
        var found = false
        text.enumerateAttribute(.memoColor, in: range) { value, _, stop in
            if value != nil {
                found = true
                stop.pointee = true
            }
        }
        return found
    }
}
