import Foundation
import Testing
import UIKit
@testable import IrodoriNotes

/// 本文 ⇔ 保存用 HTML（Android 版の MemoHtmlTest と同じ内容）。
struct MemoHtmlTests {

    private func roundTrip(_ text: String) -> String {
        MemoHtml.toPlainText(MemoHtml.toHtml(NSAttributedString(string: text)))
    }

    @Test func toHtml_escapesAndConvertsLineBreaks() {
        #expect(MemoHtml.escape("a<b>&\"c") == "a&lt;b&gt;&amp;&quot;c")
        #expect(MemoHtml.escape("1\n2\r\n3\r4") == "1<br>2<br>3<br>4")
    }

    @Test(arguments: [
        "",
        "plain",
        "日本語のメモ",
        "  先頭と  連続した空白  ",
        "1行目\n\n\n4行目\n",
        "\n先頭が改行",
        "記号 <tag> & \"quote\" 'single' &amp; &lt;",
        "絵文字 😀👨‍👩‍👧🇯🇵",
        "\ttab",
        "か\u{3099}と結合文字",
    ])
    func roundTrip_keepsTextAsIs(text: String) {
        #expect(roundTrip(text) == text)
    }

    @Test func roundTrip_normalizesCarriageReturnsToLineFeed() {
        #expect(roundTrip("a\r\nb\rc") == "a\nb\nc")
    }

    @Test func fromHtml_ignoresUnknownTagsAndKeepsBrokenMarkup() {
        #expect(MemoHtml.toPlainText("<p>a</p><span>b</span>") == "ab")
        #expect(MemoHtml.toPlainText("a<br/>b") == "a\nb")
        #expect(MemoHtml.toPlainText("a<BR>b") == "a\nb")
        #expect(MemoHtml.toPlainText("a & b") == "a & b")
        #expect(MemoHtml.toPlainText("a <b") == "a <b")
    }

    /// Android 版で保存した HTML もそのまま読める（同じ形式）。
    @Test func readsHtmlWrittenByAndroid() {
        let html = "<font color=\"red\"><b>赤い太字</b></font><br><i>斜体</i>&amp;<u>下線</u>"
        let text = MemoHtml.fromHtml(html)
        #expect(text.string == "赤い太字\n斜体&下線")
        #expect(format(text, at: 0) == TextFormat(bold: true, colorKey: "red"))
        #expect(format(text, at: 5) == TextFormat(italic: true))
        #expect(format(text, at: 8) == TextFormat(underline: true))
        #expect(MemoHtml.toHtml(text) == html) // 書き戻しても同じ
    }

    // MARK: 書式

    /// 本文に書式の印を付ける（start..<end は UTF-16 の位置）。
    private func styled(_ text: String, _ marks: (TextFormat, Int, Int)...) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text)
        for (format, start, end) in marks {
            result.addAttributes(format.semanticAttributes, range: NSRange(location: start, length: end - start))
        }
        return result
    }

    private func format(_ text: NSAttributedString, at index: Int) -> TextFormat {
        TextFormat(attributes: text.attributes(at: index, effectiveRange: nil))
    }

    @Test func toHtml_writesEachStyle() {
        #expect(MemoHtml.toHtml(styled("abc", (TextFormat(bold: true), 0, 2))) == "<b>ab</b>c")
        #expect(MemoHtml.toHtml(styled("abc", (TextFormat(italic: true), 1, 3))) == "a<i>bc</i>")
        #expect(MemoHtml.toHtml(styled("abc", (TextFormat(underline: true), 0, 3))) == "<u>abc</u>")
        #expect(MemoHtml.toHtml(styled("abc", (TextFormat(colorKey: "red"), 1, 2))) == "a<font color=\"red\">b</font>c")
    }

    @Test func toHtml_overlappingStylesStayWellFormed() {
        // 太字 [0,3) と 赤 [2,5) が重なる
        let text = styled("abcde", (TextFormat(bold: true), 0, 3), (TextFormat(colorKey: "red"), 2, 5))
        #expect(MemoHtml.toHtml(text) == "<b>ab</b><font color=\"red\"><b>c</b></font><font color=\"red\">de</font>")
    }

    /// 書式と関係のない見た目の情報（フォントなど）が途中で変わっても、同じ書式の区間は1つにまとめる。
    @Test func toHtml_ignoresVisualAttributes() {
        let text = NSMutableAttributedString(attributedString: styled("abcd", (TextFormat(bold: true), 0, 4)))
        text.addAttribute(.kern, value: 1, range: NSRange(location: 2, length: 1))
        #expect(MemoHtml.toHtml(text) == "<b>abcd</b>")
    }

    @Test func roundTrip_keepsStylesAndColors() {
        let text = styled(
            "太字と赤の下線\n2行目",
            (TextFormat(bold: true), 0, 2),
            (TextFormat(colorKey: "red"), 3, 7),
            (TextFormat(underline: true), 5, 7),
            (TextFormat(italic: true), 8, 11))
        let html = MemoHtml.toHtml(text)
        let restored = MemoHtml.fromHtml(html)

        #expect(restored.string == text.string)
        #expect(MemoHtml.toHtml(restored) == html) // もう一度書き出しても同じ
        #expect(format(restored, at: 3) == TextFormat(colorKey: "red"))
        #expect(format(restored, at: 6) == TextFormat(underline: true, colorKey: "red"))
        #expect(format(restored, at: 7) == .none) // 改行には付かない
        #expect(format(restored, at: 8) == TextFormat(italic: true))
    }

    @Test func roundTrip_emojiInsideStyle() {
        let text = styled("a😀b", (TextFormat(bold: true), 1, 3)) // 😀 は UTF-16 で2つ
        let restored = MemoHtml.fromHtml(MemoHtml.toHtml(text))
        #expect(MemoHtml.toHtml(text) == "a<b>😀</b>b")
        #expect(format(restored, at: 1).bold)
        #expect(!format(restored, at: 3).bold)
    }

    @Test func fromHtml_unknownColorNameIsIgnoredButTextKept() {
        let restored = MemoHtml.fromHtml("<font color=\"no-such\">abc</font>")
        #expect(restored.string == "abc")
        #expect(format(restored, at: 0) == .none)
    }

    @Test func fromHtml_unclosedTagRunsToEnd() {
        let restored = MemoHtml.fromHtml("a<b>bc")
        #expect(!format(restored, at: 0).bold)
        #expect(format(restored, at: 2).bold)
    }
}
