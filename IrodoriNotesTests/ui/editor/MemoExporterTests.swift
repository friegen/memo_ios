import Foundation
import PDFKit
import Testing
import UIKit
@testable import IrodoriNotes

/// メモの出力（Android 版の MemoExporterTest と同じ内容。PDF のファイルも作って確かめる）。
struct MemoExporterTests {
    private let directory: URL
    private let exporter: MemoExporter

    init() {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent("MemoExporterTests-\(UUID().uuidString)")
        exporter = MemoExporter(directory: directory)
    }

    /// 「赤い字」が赤（色は名前で持っている）のメモ。
    private func coloredMemo() -> NSAttributedString {
        let text = NSMutableAttributedString(string: "買い物 <リスト>\n赤い字")
        text.addAttribute(.memoColor, value: "red", range: NSRange(location: 10, length: 3))
        return text
    }

    private func lines(_ count: Int) -> NSAttributedString {
        NSAttributedString(string: (1...count).map { "行\($0)" }.joined(separator: "\n"))
    }

    private func export(_ text: NSAttributedString, _ format: MemoExportFormat) throws -> [URL] {
        try exporter.export(text, format: format, defaultFileName: "メモ")
    }

    @Test func fileBaseName_usesFirstLineWithoutInvalidChars() {
        #expect(MemoExporter.fileBaseName("\n  買い物/リスト \n2行目", fallback: "メモ") == "買い物_リスト")
        #expect(MemoExporter.fileBaseName(" \n ", fallback: "メモ") == "メモ")
        #expect(MemoExporter.fileBaseName("...", fallback: "メモ") == "メモ")
        #expect(MemoExporter.fileBaseName(String(repeating: "a", count: 40), fallback: "メモ") == String(repeating: "a", count: 30))
        // 絵文字の途中で切らない（Android と同じく UTF-16 で30まで）
        #expect(MemoExporter.fileBaseName(String(repeating: "a", count: 29) + "😀😀", fallback: "メモ") == String(repeating: "a", count: 29))
    }

    @Test func imageFileName_numbersOnlyWhenSeveral() {
        #expect(MemoExporter.imageFileName("メモ", index: 0, count: 1) == "メモ.png")
        #expect(MemoExporter.imageFileName("メモ", index: 0, count: 3) == "メモ_01.png")
        #expect(MemoExporter.imageFileName("メモ", index: 2, count: 120) == "メモ_003.png")
    }

    @Test func text_isPlainTextNamedByFirstLine() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try #require(try export(coloredMemo(), .text).first)
        #expect(file.lastPathComponent == "買い物 _リスト_.txt")
        #expect(try String(contentsOf: file, encoding: .utf8) == "買い物 <リスト>\n赤い字")
    }

    @Test func html_keepsFormattingWithLightThemeColors() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try #require(try export(coloredMemo(), .html).first)
        let html = try String(contentsOf: file, encoding: .utf8)
        #expect(html.contains("<meta charset=\"utf-8\">"))
        #expect(html.contains("<title>買い物 _リスト_</title>"))
        #expect(html.contains("買い物 &lt;リスト&gt;<br><font color=\"red\">赤い字</font>"))
        // 色の名前ごとに、ライトテーマの色を当てる（ダークテーマの色ではない）
        let red = try #require(MemoExporter.lightColor("red"))
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        red.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hex = String(format: "#%02X%02X%02X", Int((r * 255).rounded()), Int((g * 255).rounded()), Int((b * 255).rounded()))
        #expect(html.contains("font[color=\"red\"] { color: \(hex); }"))
        #expect(html.contains("background: #FFFFFF"))
    }

    /// ページ分け: 行の途中で切らず、全部の行がどこかのページに入る。
    @Test func pageLayout_splitsByHeight() {
        let width = MemoExportLayout.pdfPageWidth - MemoExportLayout.pdfMargin * 2
        let height = MemoExportLayout.pdfPageHeight - MemoExportLayout.pdfMargin * 2
        let short = MemoPageLayout(text: MemoExporter.styled(NSAttributedString(string: "短いメモ"), size: 11.5), width: width)
        #expect(short.pages(pageHeight: height).count == 1)

        let long = MemoPageLayout(text: MemoExporter.styled(lines(200), size: 11.5), width: width)
        let pages = long.pages(pageHeight: height)
        #expect(pages.count > 1)
        #expect(pages.first?.lowerBound == 0)
        #expect(pages.last?.upperBound == 199)
        for page in pages { #expect(long.height(of: page) <= height) }
    }

    /// 1行だけでページを超えるときは、その行だけで1ページ（切らない）。
    @Test func splitLines_tallLineGetsItsOwnPage() {
        let tops: [CGFloat] = [0, 10, 110]
        let bottoms: [CGFloat] = [10, 110, 120]
        let pages = splitLinesIntoPages(lineCount: 3, pageHeight: 50, lineTop: { tops[$0] }, lineBottom: { bottoms[$0] })
        #expect(pages == [0...0, 1...1, 2...2])
    }

    @Test func pdf_isA4WithSeveralPagesForLongMemo() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let short = try #require(try export(coloredMemo(), .pdf).first)
        #expect(short.lastPathComponent == "買い物 _リスト_.pdf")
        let document = try #require(PDFDocument(url: short))
        #expect(document.pageCount == 1)
        let bounds = try #require(document.page(at: 0)).bounds(for: .mediaBox)
        #expect(bounds.width == 595)
        #expect(bounds.height == 842)
        #expect(document.string?.contains("赤い字") == true)

        let longFile = try #require(try export(lines(200), .pdf).first)
        let long = try #require(PDFDocument(url: longFile))
        #expect(long.pageCount > 1)
    }

    @Test func image_longMemoIsSplitIntoSeveralImages() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let short = try #require(try export(coloredMemo(), .image).first)
        #expect(short.lastPathComponent == "買い物 _リスト_.png")
        let image = try #require(UIImage(contentsOfFile: short.path)?.cgImage)
        #expect(image.width == 1080)

        let files = try export(lines(200), .image)
        #expect(files.count > 1)
        #expect(files.first?.lastPathComponent == "行1_01.png")
        for file in files {
            let height = try #require(UIImage(contentsOfFile: file.path)?.cgImage).height
            #expect(CGFloat(height) <= MemoExportLayout.imageMaxContentHeight + MemoExportLayout.imagePadding * 2)
        }
    }

    /// 背景は白（ダークテーマで使っていても同じ）。
    @Test func image_hasWhiteBackground() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let file = try #require(try export(coloredMemo(), .image).first)
        let image = try #require(UIImage(contentsOfFile: file.path)?.cgImage)
        var pixel = [UInt8](repeating: 0, count: 4)
        let context = try #require(CGContext(
            data: &pixel, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue))
        context.draw(image, in: CGRect(x: -1, y: -1, width: image.width, height: image.height)) // 左上近くの1点
        #expect(pixel[0] == 255 && pixel[1] == 255 && pixel[2] == 255)
    }

    @Test func previousExportIsRemoved() throws {
        defer { try? FileManager.default.removeItem(at: directory) }
        let first = try #require(try export(coloredMemo(), .text).first)
        _ = try export(NSAttributedString(string: "別のメモ"), .text)
        #expect(!FileManager.default.fileExists(atPath: first.path))
    }
}
