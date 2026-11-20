import Foundation
import Testing
@testable import IrodoriNotes

/// 本文 ⇔ 保存用 HTML（Android 版の MemoHtmlTest の「文字・空白・改行」の部分。書式はステップ5で足す）。
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
        #expect(MemoHtml.toPlainText("<font color=\"red\"><b>赤い太字</b></font><br><i>斜体</i>&amp;<u>下線</u>") == "赤い太字\n斜体&下線")
    }
}
