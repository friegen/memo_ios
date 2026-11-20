import Foundation

/// 1メモの文字数の上限（改行を除いた書記素単位）を超える入力を止める（Android 版の MaxCharsInputFilter にあたる）。
/// 貼り付けで上限を超える場合は、入る分だけ残す。
nonisolated enum MaxCharsLimiter {

    /// 入力（置き換え）を上限に合わせる。
    /// - Parameters:
    ///   - current: 今の本文
    ///   - range: 置き換える範囲（UTF-16。UITextView の位置の数え方）
    ///   - replacement: 入れる文字
    /// - Returns: nil なら、そのまま入れてよい。文字列なら、上限に収まるよう切った文字（空なら何も入れない）
    static func limit(current: String, range: NSRange, replacement: String, maxChars: Int) -> String? {
        if replacement.isEmpty { return nil } // 削除はいつでもできる

        let currentText = current as NSString
        let replacementText = replacement as NSString
        // 長いメモでも入力が重くならないよう、UTF-16 の長さが上限以内なら数えずに通す
        // （書記素の数は UTF-16 の長さ以下なので、その時点で上限を超えることはない）
        let resultLength = currentText.length - range.length + replacementText.length
        if resultLength <= maxChars { return nil }

        let kept = currentText.replacingCharacters(in: range, with: "")
        let remaining = maxChars - CharCounter.countChars(kept)
        if CharCounter.countChars(replacement) <= remaining { return nil }
        if remaining <= 0 { return "" }
        return replacementText.substring(to: CharCounter.endIndexOfChars(replacement, maxChars: remaining))
    }
}
