#if DEBUG
import Foundation
import GRDB

/// UI テスト（IrodoriNotesUITests）のための準備。Debug のビルドにだけ入る（ストアに出す Release には入らない）。
///
/// UI テストは起動の引数で次を指定する:
/// - `-ui-testing`: メモリ上の DB と、空の別の保存先の設定を使う（シミュレーターに入っているデータを使わない・消さない）
/// - `-ui-test-seed memos`: ダミーのメモを入れて起動する
enum UITestSupport {
    static let uiTestingArgument = "-ui-testing"
    static let seedArgument = "-ui-test-seed"

    static func makeContainerIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainer? {
        guard arguments.contains(uiTestingArgument) else { return nil }
        let suiteName = "ui-testing"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        do {
            let database = try AppDatabase.makeInMemory()
            if let index = arguments.firstIndex(of: seedArgument), index + 1 < arguments.count {
                try seed(arguments[index + 1], into: database)
            }
            return AppContainer(database: database, defaults: defaults)
        } catch {
            fatalError("UI テスト用の DB を作れませんでした: \(error)")
        }
    }

    /// ダミーのデータ（個人の情報は入れない）。
    private static func seed(_ name: String, into database: AppDatabase) throws {
        let base: Int64 = 1_763_251_200_000 // 2025-11-16 00:00 UTC
        let hour: Int64 = 60 * 60 * 1000
        switch name {
        case "memos":
            try database.writer.write { db in
                // 更新日の新しい順: Shopping list → Ideas → Meeting notes
                // 文字数の少ない順: Ideas(5) → Meeting notes(13) → Shopping list(21)
                for (text, created, updated) in [
                    ("Shopping list\nMilk\nEggs", base, base + 3 * hour),
                    ("Meeting notes", base + hour, base + hour),
                    ("Ideas", base + 2 * hour, base + 2 * hour),
                ] {
                    _ = try MemoDao.insert(db, MemoRecord(
                        folderId: nil, html: text.replacingOccurrences(of: "\n", with: "<br>"), plainText: text,
                        firstLine: CharCounter.firstLine(text, maxChars: MemoPolicy.firstLineMaxChars),
                        charCount: CharCounter.countChars(text), createdAt: created, updatedAt: updated))
                }
            }
        default:
            fatalError("知らないダミーデータ: \(name)")
        }
    }
}
#endif
