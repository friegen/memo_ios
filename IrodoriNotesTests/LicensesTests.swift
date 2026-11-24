import Foundation
import Testing
@testable import IrodoriNotes

/// オープンソースライセンスの一覧（`Resources/licenses.json`）に、使っているパッケージがすべて、今の版で載っているか。
/// Android 版は AboutLibraries が自動で作るが、iOS 版は手で管理するので、足し忘れ・版の上げ忘れをこのテストで見つける。
struct LicensesTests {

    private struct Resolved: Decodable {
        struct Pin: Decodable {
            struct State: Decodable { let version: String? }
            let identity: String
            let state: State
        }
        let pins: [Pin]
    }

    private func licenses() throws -> [LicenseEntry] {
        let url = try #require(Bundle(for: BundleToken.self).url(forResource: "licenses", withExtension: "json"))
        return try JSONDecoder().decode([LicenseEntry].self, from: Data(contentsOf: url))
    }

    /// Xcode が作るパッケージの一覧（Android の依存関係の一覧にあたる）。テストのソースの場所からたどって読む。
    private func resolvedPackages() throws -> [Resolved.Pin] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let url = root.appendingPathComponent("IrodoriNotes.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved")
        return try JSONDecoder().decode(Resolved.self, from: Data(contentsOf: url)).pins
    }

    @Test func everyPackageIsListedWithCurrentVersion() throws {
        let listed = Dictionary(try licenses().map { ($0.identity, $0) }, uniquingKeysWith: { first, _ in first })
        for package in try resolvedPackages() {
            let entry = listed[package.identity]
            #expect(entry != nil, "\(package.identity) のライセンスが licenses.json にない")
            if let entry, let version = package.state.version {
                #expect(entry.version == version, "\(package.identity) の版が licenses.json（\(entry.version ?? "なし")）と違う（\(version)）")
            }
        }
    }

    @Test func everyLicenseHasFullText() throws {
        for license in try licenses() {
            #expect(!license.name.isEmpty)
            #expect(!license.license.isEmpty)
            #expect(license.text.count > 100, "\(license.name) のライセンスの全文がない")
        }
    }

    /// 画面に出す一覧は名前の順。
    @Test func repositoryReturnsLibrariesSortedByName() async throws {
        let libraries = try await LicenseRepository(bundle: Bundle(for: BundleToken.self)).getLibraries()
        #expect(!libraries.isEmpty)
        #expect(libraries.map(\.name) == libraries.map(\.name).sorted { $0.localizedCaseInsensitiveCompare($1) == .orderedAscending })
        let grdb = try #require(libraries.first { $0.id == "grdb.swift" })
        #expect(grdb.version == "7.12.0")
        #expect(grdb.licenseName == "MIT License")
    }
}
