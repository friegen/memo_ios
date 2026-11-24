import Foundation

/// アプリで使っているオープンソースのライブラリとライセンス。
///
/// 一覧（`Resources/licenses.json`）は手で管理する（Android の AboutLibraries のような自動の仕組みがないため）。
/// パッケージを足したり版を上げたりしたら、licenses.json も直す（足し忘れ・版の違いは `LicensesTests` が見つける）。
final class LicenseRepository {
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        self.bundle = bundle
    }

    /// ライブラリの一覧。名前の順（大文字・小文字を区別しない）。
    func getLibraries() async throws -> [OssLibrary] {
        guard let url = bundle.url(forResource: "licenses", withExtension: "json") else { return [] }
        let entries = try JSONDecoder().decode([LicenseEntry].self, from: Data(contentsOf: url))
        return entries
            .map {
                OssLibrary(
                    id: $0.identity, name: $0.name, version: $0.version.flatMap { $0.isEmpty ? nil : $0 },
                    licenseName: $0.license, licenseText: $0.text)
            }
            .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
    }
}

/// licenses.json の1件。
nonisolated struct LicenseEntry: Decodable {
    let identity: String
    let name: String
    let version: String?
    let url: String?
    let license: String
    let text: String
}
