import SwiftUI

/// メモの出力の形式（編集画面のナビゲーションバーの出力ボタン → 形式を選ぶ → ファイルを作って共有）。
nonisolated enum MemoExportFormat: CaseIterable, Sendable {
    case pdf
    /// 長いメモは縦に分けて複数枚にする（`MemoExportLayout.imageMaxContentHeight`）
    case image
    /// 装飾なし
    case text
    /// 装飾あり（ブラウザで開くと文字色・太字などが残る）
    case html

    var fileExtension: String {
        switch self {
        case .pdf: "pdf"
        case .image: "png"
        case .text: "txt"
        case .html: "html"
        }
    }

    var labelKey: LocalizedStringKey {
        switch self {
        case .pdf: "export_pdf"
        case .image: "export_image"
        case .text: "export_text"
        case .html: "export_html"
        }
    }
}

/// PDF・画像の大きさ（Android 版と同じ値）。背景はいつも白（ダークテーマで使っていても、印刷や人に送るときに読みやすいように）。
/// 文字色はライトテーマの色を使う。
nonisolated enum MemoExportLayout {
    // PDF（単位はポイント。1/72 インチ）。A4 縦
    static let pdfPageWidth: CGFloat = 595
    static let pdfPageHeight: CGFloat = 842
    static let pdfMargin: CGFloat = 48
    static let pdfTextSize: CGFloat = 11.5

    // 画像（単位はピクセル）。幅はスマホの画面と同じくらい
    static let imageWidth: CGFloat = 1080
    static let imagePadding: CGFloat = 64
    static let imageTextSize: CGFloat = 42

    /// 画像1枚の本文の高さの上限。これを超えたら次の画像に分ける（スマホの画面およそ2枚分）
    static let imageMaxContentHeight: CGFloat = 3840

    /// 行間（文字の大きさに対する倍率）
    static let lineSpacing: CGFloat = 1.3

    /// ファイル名にするメモの1行目の長さの上限
    static let fileNameMaxChars = 30
}
