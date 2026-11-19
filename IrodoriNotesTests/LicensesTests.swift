import Foundation
import Testing
@testable import IrodoriNotes

/// オープンソースライセンスの一覧（`Resources/licenses.json`）に、使っているパッケージがすべて載っているか。
/// Android 版は AboutLibraries が自動で作るが、iOS 版は手で管理するので、足し忘れをこのテストで見つける。
struct LicensesTests {

    private struct License: Decodable {
        let identity: String
        let name: String
        let license: String
        let text: String
    }

    private struct Resolved: Decodable {
        struct Pin: Decodable { let identity: String }
        let pins: [Pin]
    }

    private func licenses() throws -> [License] {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "licenses", withExtension: "json"))
        return try JSONDecoder().decode([License].self, from: Data(contentsOf: url))
    }

    /// Xcode が作るパッケージの一覧（Android の依存関係の一覧にあたる）。テストのソースの場所からたどって読む。
    private func resolvedPackages() throws -> [String] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let url = root.appendingPathComponent("IrodoriNotes.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        return try JSONDecoder().decode(Resolved.self, from: Data(contentsOf: url)).pins.map(\.identity)
    }

    @Test func everyPackageIsListed() throws {
        let listed = Set(try licenses().map(\.identity))
        for package in try resolvedPackages() {
            #expect(listed.contains(package), "\(package) のライセンスが licenses.json にない")
        }
    }

    @Test func everyLicenseHasFullText() throws {
        for license in try licenses() {
            #expect(!license.name.isEmpty)
            #expect(!license.license.isEmpty)
            #expect(license.text.count > 100, "\(license.name) のライセンスの全文がない")
        }
    }
}
