import Foundation

/// 訳（String Catalog の Localizable）を読む（Android の getString / getQuantityString にあたる）。
/// SwiftUI の `Text("key")` で済むところはそちらを使い、文字列として要るときにこれを使う。
nonisolated enum L10n {

    /// キーの訳。
    static func string(_ key: String, bundle: Bundle = .main) -> String {
        bundle.localizedString(forKey: key, value: nil, table: nil)
    }

    /// 書式付きの訳（例: "Created %1$@"）。数の入った複数形（plural）の訳にも使う（数で one / other などを選ぶ）。
    /// - Parameter locale: 省略すると、アプリが実際に使っている訳の言語。
    ///   端末の言語（Locale.current）を使うと、アプリだけ別の言語にしているときに複数形の決まりが合わなくなる
    ///   （例: 端末が日本語・アプリが英語だと「1 characters」になる）ため
    static func format(_ key: String, _ arguments: any CVarArg..., bundle: Bundle = .main, locale: Locale? = nil) -> String {
        let locale = locale ?? bundle.preferredLocalizations.first.map(Locale.init(identifier:)) ?? .current
        return String(format: string(key, bundle: bundle), locale: locale, arguments: arguments)
    }

    /// 数の入った複数形の訳で、数を3桁ごとに区切って出す（例: "12,345 characters"。Android の getQuantityString に書式済みの数を渡すのと同じ見た目）。
    /// 区切り文字は端末の言語・地域に合わせる。
    static func count(_ key: String, _ count: Int, bundle: Bundle = .main, locale: Locale? = nil, numberLocale: Locale = .current) -> String {
        let text = format(key, count, bundle: bundle, locale: locale)
        let grouped = count.formatted(.number.locale(numberLocale))
        guard let range = text.range(of: String(count)) else { return text }
        return text.replacingCharacters(in: range, with: grouped)
    }
}
