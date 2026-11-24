import Foundation
import Testing
@testable import IrodoriNotes

/// データサイズの表示（Android 版の DataSizeTextTest と同じ決まり）。
struct DataSizeTextTests {
    private let english = Locale(identifier: "en_US")

    private func format(_ bytes: Int64, locale: Locale? = nil) -> String {
        DataSizeText.format(bytes, bundle: Bundle(for: BundleToken.self), locale: locale ?? english)
    }

    @Test func bytes() {
        #expect(format(0) == "0 B")
        #expect(format(1023) == "1,023 B")
    }

    /// 10KB 未満は小数1桁まで、それ以上は整数。
    @Test func kilobytes() {
        #expect(format(1024) == "1 KB")
        #expect(format(8704) == "8.5 KB") // 8.5 × 1024
        #expect(format(10 * 1024) == "10 KB")
        #expect(format(431_104) == "421 KB")
    }

    @Test func megabytes() {
        #expect(format(1024 * 1024) == "1 MB")
        #expect(format(3_355_443) == "3.2 MB")
        #expect(format(25 * 1024 * 1024) == "25 MB")
    }

    /// 小数点・3桁区切りは言語・地域に合わせる。
    @Test func usesLocaleSeparators() {
        #expect(format(8704, locale: Locale(identifier: "de_DE")) == "8,5 KB")
    }
}
