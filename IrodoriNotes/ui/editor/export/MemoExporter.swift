import UIKit

/// メモを PDF・画像・テキスト・HTML のファイルにする（Android 版の MemoExporter にあたる。共有は `ShareSheet`）。
///
/// - ファイルは一時フォルダの `exports/` に作る。出力のたびに前回のファイルは消す
/// - ファイル名はメモの1行目（使えない文字は _ にする）
/// - PDF・画像・HTML は白い背景に、ライトテーマの文字色で出す（ダークテーマで使っていても同じ）
/// 長いメモでも画面が止まらないよう、`export` はメインスレッド以外で呼んでよい（呼び出し側で別スレッドにする）。
nonisolated final class MemoExporter: Sendable {
    /// 一時フォルダの中の出力用のフォルダ
    static let exportDirectoryName = "exports"

    /// 背景（いつも白）と、色を付けていない文字の色（Android 版の export_background / export_text と同じ）
    static let backgroundColor = UIColor.white
    static let textColor = UIColor(red: 0x1C / 255, green: 0x1B / 255, blue: 0x1F / 255, alpha: 1)

    private let directory: URL

    /// - Parameter directory: 出力先。テストでは別のフォルダを渡す
    init(directory: URL = FileManager.default.temporaryDirectory.appendingPathComponent(MemoExporter.exportDirectoryName)) {
        self.directory = directory
    }

    /// - Parameters:
    ///   - text: 編集画面の本文（書式の印付き）。呼び出し側で写しを渡す（作っている間に書き換わらないように）
    ///   - defaultFileName: 何も書いていないときのファイル名（「メモ」）
    /// - Returns: 作ったファイル（画像は複数のことがある）
    func export(_ text: NSAttributedString, format: MemoExportFormat, defaultFileName: String) throws -> [URL] {
        let fileManager = FileManager.default
        try? fileManager.removeItem(at: directory) // 前回のファイルを消す
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        let baseName = Self.fileBaseName(text.string, fallback: defaultFileName)
        switch format {
        case .text:
            let url = directory.appendingPathComponent("\(baseName).txt")
            try Data(text.string.utf8).write(to: url)
            return [url]
        case .html:
            let url = directory.appendingPathComponent("\(baseName).html")
            try Data(Self.htmlDocument(text, title: baseName).utf8).write(to: url)
            return [url]
        case .pdf:
            let url = directory.appendingPathComponent("\(baseName).pdf")
            try writePdf(text, to: url)
            return [url]
        case .image:
            return try writeImages(text, baseName: baseName)
        }
    }

    // MARK: HTML

    static func htmlDocument(_ text: NSAttributedString, title: String) -> String {
        // 保存している HTML（<font color="red"> など）をそのまま使い、色の名前ごとにライトテーマの色を CSS で当てる
        let colorStyles = MemoTextColor.allCases.map { color in
            "font[color=\"\(color.rawValue)\"] { color: \(hex(lightColor(color.rawValue) ?? textColor)); }"
        }.joined(separator: "\n")
        return """
            <!DOCTYPE html>
            <html>
            <head>
            <meta charset="utf-8">
            <meta name="viewport" content="width=device-width, initial-scale=1">
            <title>\(MemoHtml.escape(title))</title>
            <style>
            body { margin: 24px; background: \(hex(backgroundColor)); color: \(hex(textColor)); font-family: sans-serif; font-size: 16px; line-height: \(MemoExportLayout.lineSpacing); }
            .memo { white-space: pre-wrap; overflow-wrap: anywhere; }
            \(colorStyles)
            </style>
            </head>
            <body>
            <div class="memo">\(MemoHtml.toHtml(text))</div>
            </body>
            </html>

            """
    }

    // MARK: PDF・画像

    private func writePdf(_ text: NSAttributedString, to url: URL) throws {
        let page = CGRect(x: 0, y: 0, width: MemoExportLayout.pdfPageWidth, height: MemoExportLayout.pdfPageHeight)
        let margin = MemoExportLayout.pdfMargin
        let layout = MemoPageLayout(text: Self.styled(text, size: MemoExportLayout.pdfTextSize), width: page.width - margin * 2)
        let pages = layout.pages(pageHeight: page.height - margin * 2)
        try UIGraphicsPDFRenderer(bounds: page).writePDF(to: url) { context in
            for lines in pages.isEmpty ? [nil] : pages.map(Optional.some) {
                context.beginPage()
                Self.backgroundColor.setFill()
                context.fill(page)
                if let lines { layout.draw(lines, at: CGPoint(x: margin, y: margin)) }
            }
        }
    }

    private func writeImages(_ text: NSAttributedString, baseName: String) throws -> [URL] {
        let width = MemoExportLayout.imageWidth
        let padding = MemoExportLayout.imagePadding
        let layout = MemoPageLayout(text: Self.styled(text, size: MemoExportLayout.imageTextSize), width: width - padding * 2)
        let pages = layout.pages(pageHeight: MemoExportLayout.imageMaxContentHeight)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1 // 1ピクセル = 1（幅 1080px の画像にする）
        format.opaque = true
        return try pages.enumerated().map { index, lines in
            // 1枚ずつ作って書き出す（枚数が多いときにメモリを使い切らないように）
            try autoreleasepool {
                let size = CGSize(width: width, height: ceil(layout.height(of: lines) + padding * 2))
                let data = UIGraphicsImageRenderer(size: size, format: format).pngData { context in
                    Self.backgroundColor.setFill()
                    context.fill(CGRect(origin: .zero, size: size))
                    layout.draw(lines, at: CGPoint(x: padding, y: padding))
                }
                let url = directory.appendingPathComponent(Self.imageFileName(baseName, index: index, count: pages.count))
                try data.write(to: url)
                return url
            }
        }
    }

    /// 出力用の見た目（決まった文字の大きさ・行間・ライトテーマの色）を、本文の書式の印から付ける。
    static func styled(_ text: NSAttributedString, size: CGFloat) -> NSAttributedString {
        let result = NSMutableAttributedString(string: text.string)
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = MemoExportLayout.lineSpacing
        text.enumerateAttributes(in: NSRange(location: 0, length: text.length)) { attributes, range, _ in
            let format = TextFormat(attributes: attributes)
            var visual = format.semanticAttributes
            visual[.font] = UIFont.systemFont(ofSize: size, weight: format.bold ? .bold : .regular)
            visual[.paragraphStyle] = paragraph
            visual[.foregroundColor] = format.colorKey.flatMap(lightColor) ?? textColor
            if format.italic { visual[.obliqueness] = 0.2 }
            if format.underline { visual[.underlineStyle] = NSUnderlineStyle.single.rawValue }
            result.setAttributes(visual, range: range)
        }
        return result
    }

    /// 文字色の名前から、ライトテーマの色。
    static func lightColor(_ key: String) -> UIColor? {
        guard let color = MemoTextColor(rawValue: key),
              let named = UIColor(named: color.assetName, in: Bundle(for: MemoExporter.self), compatibleWith: nil)
        else { return nil }
        return named.resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
    }

    // MARK: ファイル名

    /// ファイル名に使えない文字
    private static let invalidFileNameCharacters = CharacterSet(charactersIn: "\\/:*?\"<>|").union(.controlCharacters)

    /// メモの1行目からファイル名（拡張子なし）を作る。何も書いていなければ `fallback`。
    /// 長さは Android と同じく UTF-16 で30まで（絵文字などの途中では切らない）。
    static func fileBaseName(_ text: String, fallback: String) -> String {
        guard let firstLine = text.split(whereSeparator: \.isNewline)
            .map({ $0.trimmingCharacters(in: .whitespaces) })
            .first(where: { !$0.isEmpty })
        else { return fallback }
        let replaced = String(String.UnicodeScalarView(firstLine.unicodeScalars.map {
            invalidFileNameCharacters.contains($0) ? "_" : $0
        }))
        var name = String(replaced.trimmingCharacters(in: .whitespaces).drop { $0 == "." })
        if name.utf16.count > MemoExportLayout.fileNameMaxChars {
            var truncated = ""
            for character in name {
                guard truncated.utf16.count + character.utf16.count <= MemoExportLayout.fileNameMaxChars else { break }
                truncated.append(character)
            }
            name = truncated.trimmingCharacters(in: .whitespaces)
        }
        return name.isEmpty ? fallback : name
    }

    /// 1枚なら「名前.png」、複数なら「名前_01.png」のように番号を付ける（並び順が崩れないよう桁を揃える）。
    static func imageFileName(_ baseName: String, index: Int, count: Int) -> String {
        if count == 1 { return "\(baseName).png" }
        let digits = max(String(count).count, 2)
        let number = String(index + 1)
        return "\(baseName)_\(String(repeating: "0", count: max(0, digits - number.count)))\(number).png"
    }

    private static func hex(_ color: UIColor) -> String {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return String(format: "#%02X%02X%02X", Int((red * 255).rounded()), Int((green * 255).rounded()), Int((blue * 255).rounded()))
    }
}
