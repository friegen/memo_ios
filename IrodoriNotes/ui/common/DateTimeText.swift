import Foundation

/// 一覧などに出す日時の文字列。端末の言語に合った順序で「年月日 時:分」を表示する（Android 版の DateTimeText と同じ）。
/// 例: 日本語 → 2026/11/16 9:05、英語 → 11/16/2026, 9:05 AM
nonisolated enum DateTimeText {

    static func format(_ epochMillis: Int64, locale: Locale = .current, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("yyyyMMddHHmm")
        return formatter.string(from: Date(timeIntervalSince1970: Double(epochMillis) / 1000))
    }

    /// 一覧の行の「作成日 2026/11/16 9:05  更新日 2026/11/17 10:30」。更新されていなければ作成日だけ。
    /// 幅が足りないときは「更新日」の前で折り返し、日付の途中では折り返さない。
    static func createdAndUpdated(
        createdAt: Int64, updatedAt: Int64?, bundle: Bundle = .main, locale: Locale = .current, timeZone: TimeZone = .current
    ) -> String {
        let created = unbreakable(L10n.format("memo_created_at", format(createdAt, locale: locale, timeZone: timeZone), bundle: bundle))
        let updated = updatedAt.map {
            unbreakable(L10n.format("memo_updated_at", format($0, locale: locale, timeZone: timeZone), bundle: bundle))
        }
        return [created, updated].compactMap { $0 }.joined(separator: partSeparator)
    }

    /// 空白を折り返さない空白に変え、文字と文字の間に「ここで折り返さない」印（幅のない文字）を入れる
    /// （日本語は文字と文字の間でも折り返せるため）。
    private static func unbreakable(_ text: String) -> String {
        text.replacingOccurrences(of: " ", with: noBreakSpace).map(String.init).joined(separator: wordJoiner)
    }

    private static let noBreakSpace = "\u{00A0}"
    private static let wordJoiner = "\u{2060}"

    /// 作成日と更新日の間（ここでだけ折り返せる）
    private static let partSeparator = "  "
}
