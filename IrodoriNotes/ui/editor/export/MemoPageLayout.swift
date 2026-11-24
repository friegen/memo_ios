import UIKit

/// 本文を決まった幅で折り返して、ページ（PDF の1ページ・画像の1枚）に分けて描く（Android 版の MemoPageLayout にあたる）。
/// ページの境目は行と行の間にする（1行の途中で切らない）。折り返しの計算は TextKit 1（NSLayoutManager）で行う。
nonisolated final class MemoPageLayout {
    private let textStorage: NSTextStorage
    private let layoutManager = NSLayoutManager()
    private let textContainer: NSTextContainer
    /// 行の位置（上端・下端）と、その行の文字の範囲
    private(set) var lines: [(top: CGFloat, bottom: CGFloat, glyphRange: NSRange)] = []

    init(text: NSAttributedString, width: CGFloat) {
        textStorage = NSTextStorage(attributedString: text)
        textContainer = NSTextContainer(size: CGSize(width: width, height: .greatestFiniteMagnitude))
        textContainer.lineFragmentPadding = 0
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        layoutManager.ensureLayout(for: textContainer)

        var lines: [(CGFloat, CGFloat, NSRange)] = []
        layoutManager.enumerateLineFragments(forGlyphRange: NSRange(location: 0, length: layoutManager.numberOfGlyphs)) {
            rect, _, _, glyphRange, _ in
            lines.append((rect.minY, rect.maxY, glyphRange))
        }
        // 最後が改行で終わるときの空の行も1行として数える
        let extra = layoutManager.extraLineFragmentRect
        if !extra.isEmpty { lines.append((extra.minY, extra.maxY, NSRange(location: layoutManager.numberOfGlyphs, length: 0))) }
        self.lines = lines
    }

    /// 1ページの本文の高さが `pageHeight` 以下になるように、行を分ける。
    func pages(pageHeight: CGFloat) -> [ClosedRange<Int>] {
        splitLinesIntoPages(lineCount: lines.count, pageHeight: pageHeight, lineTop: { lines[$0].top }, lineBottom: { lines[$0].bottom })
    }

    /// そのページの本文の高さ。
    func height(of page: ClosedRange<Int>) -> CGFloat {
        lines[page.upperBound].bottom - lines[page.lowerBound].top
    }

    /// そのページの行だけを、origin を左上にして描く（いま描いている画像・PDF のページに）。
    func draw(_ page: ClosedRange<Int>, at origin: CGPoint) {
        let first = lines[page.lowerBound]
        let last = lines[page.upperBound]
        let glyphRange = NSRange(location: first.glyphRange.location, length: NSMaxRange(last.glyphRange) - first.glyphRange.location)
        guard glyphRange.length > 0 else { return }
        let drawOrigin = CGPoint(x: origin.x, y: origin.y - first.top)
        layoutManager.drawBackground(forGlyphRange: glyphRange, at: drawOrigin)
        layoutManager.drawGlyphs(forGlyphRange: glyphRange, at: drawOrigin)
    }
}

/// 行の上端・下端の位置から、1ページに入る行の範囲に分ける（Android 版と同じ）。
/// 1行だけでページの高さを超える場合は、その行だけで1ページにする（切らない）。
nonisolated func splitLinesIntoPages(
    lineCount: Int, pageHeight: CGFloat, lineTop: (Int) -> CGFloat, lineBottom: (Int) -> CGFloat
) -> [ClosedRange<Int>] {
    var pages: [ClosedRange<Int>] = []
    var first = 0
    while first < lineCount {
        let top = lineTop(first)
        var last = first
        while last + 1 < lineCount && lineBottom(last + 1) - top <= pageHeight { last += 1 }
        pages.append(first...last)
        first = last + 1
    }
    return pages
}
