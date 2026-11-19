import Foundation

/// メモの文字数・行数を数える（Android 版の CharCounter と同じ数え方）。
///
/// 文字数の決まり（requirements.md）:
/// - 改行は含めない
/// - 絵文字は1文字（結合文字・異体字セレクタ・ZWJ 連結の絵文字も見た目どおり1文字）
///   → Swift の `Character`（書記素クラスタ）単位で数える
nonisolated enum CharCounter {

    /// 改行の文字（Android と同じく \r\n・\r・\n だけを改行として扱う）。Swift では \r\n は1つの Character。
    private static func isLineBreak(_ character: Character) -> Bool {
        character == "\n" || character == "\r" || character == "\r\n"
    }

    /// 改行を除いた書記素クラスタの数。
    static func countChars(_ text: String) -> Int {
        var count = 0
        for character in text where !isLineBreak(character) {
            count += 1
        }
        return count
    }

    /// 行数。空文字は0行、それ以外は改行の数 + 1。
    static func countLines(_ text: String) -> Int {
        if text.isEmpty { return 0 }
        return text.reduce(1) { isLineBreak($1) ? $0 + 1 : $0 }
    }

    /// 一覧に表示する1行目。先頭が空行のメモでも中身が分かるよう、空白だけの行は飛ばし、前後の空白は削る。
    /// 絵文字などを途中で切らないよう、書記素単位で `maxChars` 文字までにする。
    static func firstLine(_ text: String, maxChars: Int) -> String {
        let lines = text.split(omittingEmptySubsequences: false, whereSeparator: isLineBreak)
        guard let line = lines.first(where: { !$0.allSatisfy(\.isWhitespace) }) else { return "" }
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        return String(trimmed.prefix(maxChars))
    }

    /// 先頭から改行以外の文字（書記素単位）を `maxChars` 文字分進んだ位置を、UTF-16 の位置で返す。
    /// 改行は数えない。text 全体が収まる場合は text の UTF-16 の長さ。
    /// 文字数の上限に達したとき、貼り付けた文字を入る分だけ残すのに使う（UITextView の位置は UTF-16 で数えるため）。
    static func endIndexOfChars(_ text: String, maxChars: Int) -> Int {
        if maxChars <= 0 { return 0 }
        var counted = 0
        var utf16Offset = 0
        for character in text {
            if !isLineBreak(character) {
                if counted == maxChars { return utf16Offset }
                counted += 1
            }
            utf16Offset += character.utf16.count
        }
        return utf16Offset
    }
}
