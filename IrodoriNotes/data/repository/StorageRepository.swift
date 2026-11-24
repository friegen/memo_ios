import Foundation

/// 端末に保存しているファイルのサイズ（設定の「データ」画面に出す）。
///
/// 数える範囲は、iCloud バックアップ・Mac や PC へのバックアップの対象になるアプリのデータ:
/// - Application Support の中すべて（DB の memo.sqlite と、書き込み途中のデータが入る -wal / -shm）
/// - 設定（UserDefaults）のファイル（Library/Preferences/<Bundle ID>.plist）
/// 一時ファイル（出力の exports/ など）はバックアップされないので数えない。
final class StorageRepository {
    private let targets: [URL]

    /// - Parameter targets: 数えるファイル・フォルダ（フォルダは中のファイルすべて）。テストでは一時フォルダを渡す
    init(targets: [URL] = StorageRepository.defaultTargets()) {
        self.targets = targets
    }

    /// アプリのデータのファイル・フォルダ。
    nonisolated static func defaultTargets() -> [URL] {
        let fileManager = FileManager.default
        var urls = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        if let library = fileManager.urls(for: .libraryDirectory, in: .userDomainMask).first,
           let bundleId = Bundle.main.bundleIdentifier {
            urls.append(library.appendingPathComponent("Preferences/\(bundleId).plist"))
        }
        return urls
    }

    /// 合計サイズ（バイト）。無いファイルは 0 として数える。
    func getDataBytes() async -> Int64 {
        let targets = targets
        return await Task.detached(priority: .userInitiated) {
            targets.reduce(0) { $0 + Self.totalBytes(of: $1) }
        }.value
    }

    /// ファイルならそのサイズ、フォルダなら中のファイルの合計（中のフォルダも含む）。
    private nonisolated static func totalBytes(of url: URL) -> Int64 {
        let keys: Set<URLResourceKey> = [.isRegularFileKey, .fileSizeKey]
        guard let values = try? url.resourceValues(forKeys: keys) else { return 0 }
        if values.isRegularFile == true { return Int64(values.fileSize ?? 0) }
        guard let enumerator = FileManager.default.enumerator(at: url, includingPropertiesForKeys: Array(keys)) else { return 0 }
        var total: Int64 = 0
        for case let file as URL in enumerator {
            guard let fileValues = try? file.resourceValues(forKeys: keys), fileValues.isRegularFile == true else { continue }
            total += Int64(fileValues.fileSize ?? 0)
        }
        return total
    }
}
