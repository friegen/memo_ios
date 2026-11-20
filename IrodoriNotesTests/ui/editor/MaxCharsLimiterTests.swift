import Foundation
import Testing
@testable import IrodoriNotes

/// 1メモの文字数の上限（Android 版の MaxCharsInputFilterTest と同じ内容。上限は5文字で試す）。
struct MaxCharsLimiterTests {

    /// current の range を inserted に置き換えたときの結果と、上限に達したか。
    private func type(_ current: String, _ inserted: String, range: NSRange? = nil) -> (text: String, limited: Bool) {
        let range = range ?? NSRange(location: (current as NSString).length, length: 0)
        let limited = MaxCharsLimiter.limit(current: current, range: range, replacement: inserted, maxChars: 5)
        let text = (current as NSString).replacingCharacters(in: range, with: limited ?? inserted)
        return (text, limited != nil)
    }

    @Test func allowsInputWithinLimit() {
        #expect(type("abc", "de") == ("abcde", false))
    }

    @Test func lineBreaksDoNotCount() {
        #expect(type("ab\nc\n", "de") == ("ab\nc\nde", false))
        #expect(type("ab\r\nc", "de") == ("ab\r\ncde", false))
    }

    @Test func pasteOverLimit_keepsOnlyWhatFits() {
        #expect(type("abc", "defgh") == ("abcde", true))
    }

    @Test func atLimit_rejectsMore() {
        #expect(type("abcde", "f") == ("abcde", true))
    }

    @Test func emojiCountsAsOneAndIsNotSplit() {
        #expect(type("abc", "😀👍🏽") == ("abc😀👍🏽", false))
        #expect(type("abcd", "😀👍🏽").text == "abcd😀")
    }

    @Test func replacingSelectionCountsOnlyRemainingText() {
        // "abcde" の "bcd" を "xyz" に置き換える → 上限ちょうど
        #expect(type("abcde", "xyz", range: NSRange(location: 1, length: 3)) == ("axyze", false))
    }

    @Test func deletionIsAlwaysAllowed() {
        #expect(type("abcde", "", range: NSRange(location: 2, length: 3)) == ("ab", false))
    }
}
