import Foundation

/// メモ本文と、DB に保存する HTML との変換（Android 版の MemoHtml と同じ形式）。
///
/// Apple 標準の HTML の読み込み（NSAttributedString の .html）は中で WebKit を使うので重く、空白も変えてしまうため使わず、
/// 扱うタグを絞った自前の変換にしている（Android 版が Html.toHtml / fromHtml を使わなかったのと同じ理由）。
///
/// 使うタグ（Android と同じ）:
/// - 改行: `<br>`
/// - 太字 `<b>`、斜体 `<i>`、下線 `<u>`
/// - 文字色 `<font color="red">`（値は色の名前。表示する色はライト／ダークで変わるため、名前を保存する）
///
/// 書き出しは「同じ装飾が続く区間ごと」に `<font><b><i><u>…</u></i></b></font>` の順で囲むので、タグの入れ子が崩れない。
/// 本文の装飾は意味の情報（`.memoBold` などの印。`MemoTextFormat.swift`）で持つ。見た目（フォント・色）は使わない。
nonisolated enum MemoHtml {

    // MARK: 本文 → HTML

    /// 本文（装飾付き）を HTML にする。
    static func toHtml(_ text: NSAttributedString) -> String {
        let string = text.string as NSString
        var out = ""
        // 装飾が変わる位置で区切り、同じ装飾が続く区間はまとめる
        var segments: [(range: NSRange, format: TextFormat)] = []
        text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
            let format = TextFormat(attributes: attributes)
            if let last = segments.last, last.format == format, NSMaxRange(last.range) == range.location {
                segments[segments.count - 1].range.length += range.length
            } else {
                segments.append((range, format))
            }
        }
        for (range, format) in segments {
            if let colorKey = format.colorKey { out += "<font color=\"\(escape(colorKey))\">" }
            if format.bold { out += "<b>" }
            if format.italic { out += "<i>" }
            if format.underline { out += "<u>" }
            out += escape(string.substring(with: range))
            if format.underline { out += "</u>" }
            if format.italic { out += "</i>" }
            if format.bold { out += "</b>" }
            if format.colorKey != nil { out += "</font>" }
        }
        return out
    }

    /// < > & " をエスケープし、改行（\n・\r\n・\r）は <br> にする。空白はそのまま残す。
    static func escape(_ text: String) -> String {
        var out = ""
        out.reserveCapacity(text.utf8.count + 8)
        let scalars = Array(text.unicodeScalars)
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            switch scalar {
            case "<": out += "&lt;"
            case ">": out += "&gt;"
            case "&": out += "&amp;"
            case "\"": out += "&quot;"
            case "\r":
                // \r\n と単独の \r はどちらも改行1つとして扱う
                if index + 1 < scalars.count, scalars[index + 1] == "\n" { index += 1 }
                out += "<br>"
            case "\n": out += "<br>"
            default: out.unicodeScalars.append(scalar)
            }
            index += 1
        }
        return out
    }

    // MARK: HTML → 本文

    /// `toHtml` で作った HTML を、装飾なしの本文（文字だけ）に戻す。
    static func toPlainText(_ html: String) -> String {
        fromHtml(html).string
    }

    /// `toHtml` で作った HTML を、装飾の印（意味の情報）付きの本文に戻す。知らないタグ・知らない色の名前は無視する。
    /// 見た目（フォント・色）は付けないので、画面に出すときは `MemoTextAttributes` で付ける。
    static func fromHtml(_ html: String) -> NSAttributedString {
        var out = String.UnicodeScalarView()
        var length = 0 // out の UTF-16 の長さ（装飾の範囲は UTF-16 の位置で持つ）
        var openTags: [(name: String, start: Int, colorKey: String?)] = []
        var closedTags: [(name: String, range: NSRange, colorKey: String?)] = []
        let scalars = Array(html.unicodeScalars)

        func append(_ scalar: Unicode.Scalar) {
            out.append(scalar)
            length += scalar.utf16.count
        }

        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            if scalar == "<", let end = scalars[(index + 1)...].firstIndex(of: ">") {
                let tag = String(String.UnicodeScalarView(scalars[(index + 1)..<end])).trimmingCharacters(in: .whitespaces)
                let name = tagName(tag)
                if name == "br" {
                    append("\n")
                } else if styleTags.contains(name) {
                    if tag.hasPrefix("/") {
                        if let open = openTags.lastIndex(where: { $0.name == name }) {
                            let tag = openTags.remove(at: open)
                            closedTags.append((name, NSRange(location: tag.start, length: length - tag.start), tag.colorKey))
                        }
                    } else {
                        openTags.append((name, length, name == "font" ? colorAttribute(tag) : nil))
                    }
                }
                // 知らないタグは無視する
                index = end + 1
                continue
            }
            if scalar == "&", let end = scalars[(index + 1)...].firstIndex(of: ";"), end - index <= 8,
               let decoded = decodeEntity(String(String.UnicodeScalarView(scalars[(index + 1)..<end])))
            {
                append(decoded)
                index = end + 1
                continue
            }
            append(scalar)
            index += 1
        }
        // 閉じられていないタグは最後まで
        for tag in openTags.reversed() {
            closedTags.append((tag.name, NSRange(location: tag.start, length: length - tag.start), tag.colorKey))
        }

        let result = NSMutableAttributedString(string: String(out))
        for tag in closedTags where tag.range.length > 0 {
            switch tag.name {
            case "b": result.addAttribute(.memoBold, value: true, range: tag.range)
            case "i": result.addAttribute(.memoItalic, value: true, range: tag.range)
            case "u": result.addAttribute(.memoUnderline, value: true, range: tag.range)
            case "font":
                if let key = tag.colorKey, MemoTextColor(rawValue: key) != nil {
                    result.addAttribute(.memoColor, value: key, range: tag.range)
                }
            default: break
            }
        }
        return result
    }

    private static let styleTags: Set<String> = ["b", "i", "u", "font"]

    /// `<font color="red">` の color の値。
    private static func colorAttribute(_ tag: String) -> String? {
        guard let match = tag.firstMatch(of: /color\s*=\s*"([^"]*)"/) else { return nil }
        return String(match.1)
    }

    /// タグの名前（"br/" → "br"、"/b" → "b"、"font color=..." → "font"）。
    static func tagName(_ tag: String) -> String {
        let withoutSlash = tag.hasPrefix("/") ? String(tag.dropFirst()) : tag
        return withoutSlash.split(whereSeparator: { $0 == " " || $0 == "/" }).first.map { $0.lowercased() } ?? ""
    }

    private static func decodeEntity(_ entity: String) -> Unicode.Scalar? {
        switch entity {
        case "lt": "<"
        case "gt": ">"
        case "amp": "&"
        case "quot": "\""
        default: nil
        }
    }
}
