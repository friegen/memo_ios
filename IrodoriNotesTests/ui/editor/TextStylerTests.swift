import Foundation
import Testing
@testable import IrodoriNotes

/// 書式の付け外し（Android 版の TextStylerTest と同じ内容）。
struct TextStylerTests {

    private func text(_ string: String, _ marks: (TextFormat, Int, Int)...) -> NSMutableAttributedString {
        let result = NSMutableAttributedString(string: string)
        for (format, start, end) in marks {
            result.addAttributes(format.semanticAttributes, range: NSRange(location: start, length: end - start))
        }
        return result
    }

    private func range(_ start: Int, _ end: Int) -> NSRange { NSRange(location: start, length: end - start) }

    @Test func toggle_addsThenRemoves() {
        let t = text("abc")
        TextStyler.toggleStyle(t, range(0, 3), .bold)
        #expect(MemoHtml.toHtml(t) == "<b>abc</b>")
        TextStyler.toggleStyle(t, range(0, 3), .bold)
        #expect(MemoHtml.toHtml(t) == "abc")
    }

    @Test func toggle_partlyStyled_appliesToWholeSelection() {
        let t = text("abcde", (TextFormat(italic: true), 2, 3))
        TextStyler.toggleStyle(t, range(1, 4), .italic) // 一部だけ斜体 → 全体を斜体に
        #expect(MemoHtml.toHtml(t) == "a<i>bcd</i>e")
    }

    @Test func toggle_removingFromMiddle_keepsOutsideParts() {
        let t = text("abcde", (TextFormat(underline: true), 0, 5))
        TextStyler.toggleStyle(t, range(1, 4), .underline)
        #expect(MemoHtml.toHtml(t) == "<u>a</u>bcd<u>e</u>")
    }

    @Test func removingBoldFromBoldItalic_keepsItalic() {
        let t = text("abc", (TextFormat(bold: true, italic: true), 0, 3))
        TextStyler.toggleStyle(t, range(0, 3), .bold)
        #expect(MemoHtml.toHtml(t) == "<i>abc</i>")
    }

    @Test func setColor_replacesAndDefaultRemoves() {
        let t = text("abcde", (TextFormat(colorKey: "red"), 0, 5))
        TextStyler.setColor(t, range(2, 4), "blue")
        #expect(MemoHtml.toHtml(t) == "<font color=\"red\">ab</font><font color=\"blue\">cd</font><font color=\"red\">e</font>")
        #expect(TextStyler.uniformColorKey(t, range(0, 3)) == nil) // 赤と青が混在
        #expect(TextStyler.uniformColorKey(t, range(2, 4)) == "blue")

        TextStyler.setColor(t, range(0, 5), nil) // 既定の色に戻す
        #expect(MemoHtml.toHtml(t) == "abcde")
    }

    @Test func uniformColorKey_noColorAndPartlyColored() {
        let t = text("abc", (TextFormat(colorKey: "red"), 0, 1))
        #expect(TextStyler.uniformColorKey(t, range(1, 3)) == nil) // 色なし
        #expect(TextStyler.uniformColorKey(t, range(0, 2)) == nil) // 一部だけ赤
        #expect(TextStyler.hasAnyColor(t, range(0, 2)))
        #expect(!TextStyler.hasAnyColor(t, range(1, 3)))
    }

    // MARK: 入力する文字の書式（書式パネルの状態）

    @Test func formatOf_cursorUsesCharacterBefore_andStartIsPlain() {
        let t = text("abc", (TextFormat(bold: true), 0, 2), (TextFormat(colorKey: "red"), 1, 2))
        #expect(TextStyler.formatOf(t, range(2, 2)) == TextFormat(bold: true, colorKey: "red")) // 「b」の後ろ
        #expect(TextStyler.formatOf(t, range(3, 3)) == .none) // 「c」の後ろ
        #expect(TextStyler.formatOf(t, range(0, 0)) == .none) // 先頭
        #expect(TextStyler.formatOf(t, range(0, 2)) == TextFormat(bold: true)) // 選択範囲（色は一部だけ）
    }

    @Test func formatOf_cursorAfterEmojiReadsWholeEmoji() {
        let t = text("a😀", (TextFormat(italic: true), 1, 3))
        #expect(TextStyler.formatOf(t, range(3, 3)) == TextFormat(italic: true))
    }

    @Test func applyFormat_setsExactFormat() {
        let t = text("abc", (TextFormat(bold: true, underline: true), 0, 3))
        TextStyler.applyFormat(t, range(1, 2), TextFormat(italic: true, colorKey: "blue"))
        #expect(MemoHtml.toHtml(t) == "<b><u>a</u></b><font color=\"blue\"><i>b</i></font><b><u>c</u></b>")
        TextStyler.applyFormat(t, range(0, 3), .none)
        #expect(MemoHtml.toHtml(t) == "abc")
    }
}
