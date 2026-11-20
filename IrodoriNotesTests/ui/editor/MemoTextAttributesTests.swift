import Foundation
import Testing
import UIKit
@testable import IrodoriNotes

/// 書式の見た目（フォント・斜体・下線・文字色）。
struct MemoTextAttributesTests {
    let settings = EditorSettings(fontSize: .large, lineSpacing: .wide)

    @Test func boldItalicUnderlineAndColor() throws {
        let attributes = MemoTextAttributes.attributes(
            for: TextFormat(bold: true, italic: true, underline: true, colorKey: "red"), settings: settings)
        let font = try #require(attributes[.font] as? UIFont)
        #expect(font.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(attributes[.obliqueness] as? Double == 0.2) // 日本語にも効くよう、文字を傾けて斜体にする
        #expect(attributes[.underlineStyle] as? Int == NSUnderlineStyle.single.rawValue)
        #expect(attributes[.memoColor] as? String == "red") // 保存用の印も付く
        #expect((attributes[.paragraphStyle] as? NSParagraphStyle)?.lineHeightMultiple == 1.5)
    }

    @Test func plainHasNoStyles() throws {
        let attributes = MemoTextAttributes.attributes(for: .none, settings: settings)
        let font = try #require(attributes[.font] as? UIFont)
        #expect(!font.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(attributes[.obliqueness] == nil)
        #expect(attributes[.underlineStyle] == nil)
        #expect(attributes[.memoBold] == nil)
        #expect(attributes[.foregroundColor] as? UIColor == .label)
    }

    /// 文字色はライト／ダークで変わる（どちらの背景でも読めるように）。
    @Test func textColorsDifferBetweenLightAndDark() throws {
        for color in MemoTextColor.allCases {
            let uiColor = try #require(MemoTextAttributes.dynamicPalette(color.rawValue), "\(color) の色がない")
            let light = uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
            let dark = uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: .dark))
            #expect(light != dark, "\(color) がライトとダークで同じ")
        }
        #expect(MemoTextAttributes.dynamicPalette("no-such") == nil)
    }

    /// 文字の大きさを変えても、太字・斜体などは残る。
    @Test func applyVisuals_keepsFormatWhenSettingsChange() throws {
        let text = NSMutableAttributedString(attributedString: MemoHtml.fromHtml("<b>ab</b>c"))
        MemoTextAttributes.applyVisuals(to: text, settings: EditorSettings(fontSize: .small))
        MemoTextAttributes.applyVisuals(to: text, settings: EditorSettings(fontSize: .extraLarge))

        let boldFont = try #require(text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont)
        let plainFont = try #require(text.attribute(.font, at: 2, effectiveRange: nil) as? UIFont)
        #expect(boldFont.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(!plainFont.fontDescriptor.symbolicTraits.contains(.traitBold))
        #expect(plainFont.pointSize > MemoTextAttributes.font(settings: EditorSettings(fontSize: .small), bold: false).pointSize)
        #expect(MemoHtml.toHtml(text) == "<b>ab</b>c")
    }

    /// 入力欄は文字を傾ける指定が効く描き方（TextKit 1）を使う（新しい描き方では斜体が出ないため）。
    @Test func editorUsesTextKit1SoObliquenessIsDrawn() {
        let textView = MemoTextView.makeTextView()
        #expect(textView.textLayoutManager == nil)
        #expect(!textView.allowsEditingTextAttributes) // 貼り付けは文字だけ
    }
}
