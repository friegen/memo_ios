import Testing
@testable import IrodoriNotes

/// 文字数・行数・1行目（Android 版の CharCounterTest と同じ内容）。
struct CharCounterTests {

    @Test func countChars_empty_isZero() {
        #expect(CharCounter.countChars("") == 0)
    }

    @Test func countChars_asciiAndJapanese() {
        #expect(CharCounter.countChars("hello") == 5)
        #expect(CharCounter.countChars("こんにちは") == 5)
        #expect(CharCounter.countChars("メモabc漢字") == 7)
    }

    @Test func countChars_excludesLineBreaks() {
        #expect(CharCounter.countChars("ab\ncd") == 4)
        #expect(CharCounter.countChars("ab\r\ncd") == 4)
        #expect(CharCounter.countChars("ab\rcd") == 4)
        #expect(CharCounter.countChars("\n\n\r\n") == 0)
    }

    @Test func countChars_includesSpaces() {
        #expect(CharCounter.countChars("a b") == 3)
        #expect(CharCounter.countChars("a　b") == 3) // 全角スペース
    }

    @Test func countChars_emojiIsOneChar() {
        #expect(CharCounter.countChars("😀") == 1) // サロゲートペア
        #expect(CharCounter.countChars("👍🏽") == 1) // 肌の色の修飾
        #expect(CharCounter.countChars("🇯🇵") == 1) // 国旗
        #expect(CharCounter.countChars("👨‍👩‍👧") == 1) // ZWJ で連結した家族
        #expect(CharCounter.countChars("❤️") == 1) // 異体字セレクタ付き
        #expect(CharCounter.countChars("a😀b") == 3)
    }

    @Test func countChars_combiningCharacterIsOneChar() {
        #expect(CharCounter.countChars("か\u{3099}") == 1) // 「か」＋結合用濁点 = 「が」
    }

    @Test func countLines() {
        #expect(CharCounter.countLines("") == 0)
        #expect(CharCounter.countLines("abc") == 1)
        #expect(CharCounter.countLines("abc\ndef") == 2)
        #expect(CharCounter.countLines("abc\r\ndef") == 2)
        #expect(CharCounter.countLines("abc\rdef") == 2)
        #expect(CharCounter.countLines("abc\n\n") == 3)
    }

    @Test func firstLine_skipsBlankLinesAndTrims() {
        #expect(CharCounter.firstLine("1行目\n2行目", maxChars: 50) == "1行目")
        #expect(CharCounter.firstLine("\n   \n  本文  \n次", maxChars: 50) == "本文")
        #expect(CharCounter.firstLine("\r\n\u{3000}\r\n本文\r\n次", maxChars: 50) == "本文") // 全角スペースだけの行も飛ばす
        #expect(CharCounter.firstLine(" \n ", maxChars: 50) == "")
        #expect(CharCounter.firstLine("", maxChars: 50) == "")
    }

    @Test func firstLine_isCutByCharactersWithoutBreakingEmoji() {
        #expect(CharCounter.firstLine("あいうえお", maxChars: 3) == "あいう")
        #expect(CharCounter.firstLine("a👨‍👩‍👧bcd", maxChars: 3) == "a👨‍👩‍👧b") // ZWJ の絵文字を途中で切らない
        #expect(CharCounter.firstLine("ab", maxChars: 3) == "ab")
    }

    @Test func endIndexOfChars_skipsLineBreaksAndKeepsGraphemes() {
        #expect(CharCounter.endIndexOfChars("abcdef", maxChars: 3) == 3)
        #expect(CharCounter.endIndexOfChars("ab\ncdef", maxChars: 3) == 4) // 改行は数えない
        #expect(CharCounter.endIndexOfChars("ab\r\ncdef", maxChars: 3) == 5) // \r\n も改行1つ（UTF-16 では2つ分）
        #expect(CharCounter.endIndexOfChars("a😀b", maxChars: 2) == "a😀".utf16.count) // 絵文字を途中で切らない
        #expect(CharCounter.endIndexOfChars("ab", maxChars: 5) == 2) // 全部入る
        #expect(CharCounter.endIndexOfChars("ab", maxChars: 0) == 0)
    }
}
