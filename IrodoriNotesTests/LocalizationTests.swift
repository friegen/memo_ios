import Foundation
import Testing
@testable import IrodoriNotes

/// 文字列が対応している9言語すべてにそろっているか（Android の StringResourcesTest にあたる）。
struct LocalizationTests {
    /// 対応言語（requirements.md「対応言語」）。英語が既定。
    static let languages = ["en", "ja", "es", "pt", "fr", "de", "ko", "zh-Hant", "id"]

    /// アプリに入っている、ある言語・ある表（Localizable / InfoPlist）の文字列。
    private func strings(language: String, table: String) throws -> [String: String] {
        let appBundle = Bundle(for: BundleToken.self)
        let path = try #require(appBundle.path(forResource: table, ofType: "strings", inDirectory: nil, forLocalization: language),
                                "\(language) の \(table).strings がない")
        let dictionary = try #require(NSDictionary(contentsOfFile: path) as? [String: String])
        return dictionary
    }

    @Test(arguments: ["Localizable", "InfoPlist"])
    func allLanguagesHaveSameKeys(table: String) throws {
        let english = try strings(language: "en", table: table)
        #expect(!english.isEmpty)
        for language in Self.languages {
            let localized = try strings(language: language, table: table)
            #expect(Set(localized.keys) == Set(english.keys), "\(language) の \(table) のキーが英語とちがう")
            for (key, value) in localized {
                #expect(!value.isEmpty, "\(language) の \(key) が空")
            }
        }
    }

    /// Android の strings.xml の書き方（’ などの文字コード・\' など）が、変換されずに残っていない。
    @Test func noAndroidEscapesRemain() throws {
        for language in Self.languages {
            for (key, value) in try strings(language: language, table: "Localizable") {
                #expect(!value.contains("\\u"), "\(language) の \(key) に \\u が残っている: \(value)")
                #expect(!value.contains("\\'") && !value.contains("\\\""), "\(language) の \(key) に \\ が残っている: \(value)")
            }
        }
    }

    @Test func appNameIsJapaneseOnlyInJapanese() throws {
        for language in Self.languages {
            let expected = language == "ja" ? "いろどりメモ" : "Irodori Notes"
            #expect(try strings(language: language, table: "InfoPlist")["CFBundleDisplayName"] == expected)
            #expect(try strings(language: language, table: "Localizable")["app_name"] == expected)
        }
    }
}
