import Foundation
import Testing
@testable import IrodoriNotes

/// 訳の読み込み（書式・複数形）。
struct L10nTests {

    private func bundle(_ language: String) throws -> Bundle {
        let path = try #require(Bundle(for: BundleToken.self).path(forResource: language, ofType: "lproj"))
        return try #require(Bundle(path: path))
    }

    @Test func pluralChoosesFormByCount() throws {
        let en = try bundle("en")
        let english = Locale(identifier: "en_US")
        #expect(L10n.format("memo_char_count_description", 1, bundle: en, locale: english) == "1 character")
        #expect(L10n.format("memo_char_count_description", 2, bundle: en, locale: english) == "2 characters")

        let ja = try bundle("ja")
        #expect(L10n.format("memo_char_count_description", 2, bundle: ja, locale: Locale(identifier: "ja_JP")) == "2文字")
    }

    /// 省略したときは、アプリが使っている訳の言語の複数形の決まりで選ぶ（端末の言語が日本語でも英語の訳なら「1 character」）。
    @Test func defaultLocaleFollowsTranslationLanguage() throws {
        let main = Bundle(for: BundleToken.self)
        let language = try #require(main.preferredLocalizations.first)
        if language == "en" {
            #expect(L10n.format("memo_char_count_description", 1) == "1 character")
        } else if language == "ja" {
            #expect(L10n.format("memo_char_count_description", 1) == "1文字")
        }
    }

    @Test func formatWithStringArgument() throws {
        #expect(L10n.format("memo_created_at", "X", bundle: try bundle("en")) == "Created X")
        #expect(L10n.format("memo_created_at", "X", bundle: try bundle("ja")) == "作成日 X")
    }

    /// 数を3桁ごとに区切る（Android の getQuantityString に書式済みの数を渡すのと同じ見た目）。
    @Test func countGroupsDigits() throws {
        let en = try bundle("en")
        let english = Locale(identifier: "en_US")
        #expect(L10n.count("editor_char_count", 12_345, bundle: en, locale: english, numberLocale: english) == "12,345 characters")
        #expect(L10n.count("editor_char_count", 1, bundle: en, locale: english, numberLocale: english) == "1 character")
        #expect(L10n.count("editor_line_count", 3, bundle: try bundle("ja"), locale: Locale(identifier: "ja_JP"),
                           numberLocale: Locale(identifier: "ja_JP")) == "3行")
        #expect(L10n.count("editor_char_count", 12_345, bundle: try bundle("de"), locale: Locale(identifier: "de_DE"),
                           numberLocale: Locale(identifier: "de_DE")) == "12.345 Zeichen")
    }
}
