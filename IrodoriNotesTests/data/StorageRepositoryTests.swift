import Foundation
import Testing
@testable import IrodoriNotes

/// データサイズの計算（Android 版の StorageRepositoryTest にあたる）。一時フォルダにファイルを作って数える。
struct StorageRepositoryTests {
    private let root: URL

    init() throws {
        root = FileManager.default.temporaryDirectory.appendingPathComponent("StorageRepositoryTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    }

    private func write(_ name: String, bytes: Int) throws -> URL {
        let url = root.appendingPathComponent(name)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data(repeating: 0, count: bytes).write(to: url)
        return url
    }

    /// フォルダは中のファイルすべて（中のフォルダも含む）、ファイルはそのサイズを足す。
    @Test func sumsFilesInFoldersAndSingleFiles() async throws {
        defer { try? FileManager.default.removeItem(at: root) }
        _ = try write("support/memo.sqlite", bytes: 1000)
        _ = try write("support/memo.sqlite-wal", bytes: 200)
        _ = try write("support/sub/other", bytes: 30)
        let plist = try write("prefs.plist", bytes: 4)

        let repository = StorageRepository(targets: [root.appendingPathComponent("support"), plist])
        #expect(await repository.getDataBytes() == 1234)
    }

    /// 無いファイル・フォルダは 0。
    @Test func missingTargetsCountAsZero() async throws {
        defer { try? FileManager.default.removeItem(at: root) }
        let repository = StorageRepository(targets: [root.appendingPathComponent("none"), root.appendingPathComponent("none.plist")])
        #expect(await repository.getDataBytes() == 0)
    }

    /// アプリのデータの場所: Application Support と、設定のファイル。
    @Test func defaultTargetsAreApplicationSupportAndPreferences() {
        let paths = StorageRepository.defaultTargets().map(\.path)
        #expect(paths.contains { $0.hasSuffix("Library/Application Support") })
        #expect(paths.contains { $0.hasSuffix("Library/Preferences/xyz.friegen.memo.plist") })
    }
}
