import Foundation

/// メモ本文と、DB に保存する HTML との変換（Android 版の MemoHtml と同じ形式）。
///
/// Apple 標準の HTML の読み込み（NSAttributedString の .html）は中で WebKit を使うので重く、空白も変えてしまうため使わず、
/// 扱うタグを絞った自前の変換にしている（Android 版が Html.toHtml / fromHtml を使わなかったのと同じ理由）。
///
/// 使うタグ（Android と同じ）:
/// - 改行: `<br>`
/// - 太字 `<b>`、斜体 `<i>`、下線 `<u>`、文字色 `<font color="red">`（ステップ5で対応する）
nonisolated enum MemoHtml {

    // MARK: 本文 → HTML

    /// 本文（装飾付き）を HTML にする。
    /// TODO(ステップ5): 太字・斜体・下線・文字色を書き出す。今は文字・空白・改行だけ
    static func toHtml(_ text: NSAttributedString) -> String {
        escape(text.string)
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

    /// `toHtml` で作った HTML を、装飾なしの本文（文字だけ）に戻す。知らないタグは無視する。
    static func toPlainText(_ html: String) -> String {
        var out = String.UnicodeScalarView()
        let scalars = Array(html.unicodeScalars)
        var index = 0
        while index < scalars.count {
            let scalar = scalars[index]
            if scalar == "<", let end = scalars[(index + 1)...].firstIndex(of: ">") {
                let tag = String(String.UnicodeScalarView(scalars[(index + 1)..<end])).trimmingCharacters(in: .whitespaces)
                if tagName(tag) == "br" { out.append("\n") }
                index = end + 1
                continue
            }
            if scalar == "&", let end = scalars[(index + 1)...].firstIndex(of: ";"), end - index <= 8,
               let decoded = decodeEntity(String(String.UnicodeScalarView(scalars[(index + 1)..<end])))
            {
                out.append(decoded)
                index = end + 1
                continue
            }
            out.append(scalar)
            index += 1
        }
        return String(out)
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
