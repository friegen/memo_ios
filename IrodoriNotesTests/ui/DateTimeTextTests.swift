import Foundation
import Testing
@testable import IrodoriNotes

/// 一覧の日時の表示。
struct DateTimeTextTests {
    /// 2026-11-16 09:05 UTC
    let millis: Int64 = 1_794_819_900_000
    let utc = TimeZone(identifier: "UTC")!

    @Test func formatFollowsLanguage() {
        #expect(DateTimeText.format(millis, locale: Locale(identifier: "ja_JP"), timeZone: utc) == "2026/11/16 9:05")
        #expect(DateTimeText.format(millis, locale: Locale(identifier: "de_DE"), timeZone: utc) == "16.11.2026, 09:05")
        #expect(DateTimeText.format(millis, locale: Locale(identifier: "en_US"), timeZone: utc).contains("11/16/2026"))
    }

    @Test func createdAndUpdated_breaksOnlyBetweenParts() throws {
        let path = try #require(Bundle(for: BundleToken.self).path(forResource: "ja", ofType: "lproj"))
        let ja = try #require(Bundle(path: path))
        let locale = Locale(identifier: "ja_JP")

        let onlyCreated = DateTimeText.createdAndUpdated(createdAt: millis, updatedAt: nil, bundle: ja, locale: locale, timeZone: utc)
        let both = DateTimeText.createdAndUpdated(createdAt: millis, updatedAt: millis + 60_000, bundle: ja, locale: locale, timeZone: utc)

        // 折り返さない印（幅のない文字・折り返さない空白）を取り除くと、ふつうの文になる
        let plain = { (text: String) in text.replacingOccurrences(of: "\u{2060}", with: "").replacingOccurrences(of: "\u{00A0}", with: " ") }
        #expect(plain(onlyCreated) == "作成日 2026/11/16 9:05")
        #expect(plain(both) == "作成日 2026/11/16 9:05  更新日 2026/11/16 9:06")
        // 折り返せる空白は、作成日と更新日の間だけ
        #expect(both.filter { $0 == " " }.count == 2)
    }
}
