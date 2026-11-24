#if DEBUG
import Foundation
import GRDB

/// UI テスト（IrodoriNotesUITests）のための準備。Debug のビルドにだけ入る（ストアに出す Release には入らない）。
///
/// UI テストは起動の引数で次を指定する:
/// - `-ui-testing`: メモリ上の DB と、空の別の保存先の設定を使う（シミュレーターに入っているデータを使わない・消さない）
/// - `-ui-test-seed memos` / `folders` / `deep` / `trash` / `locked`: ダミーのメモ・フォルダ・5階層のフォルダ・ゴミ箱の中身・ロックしたものを入れて起動する
/// - `-ui-test-auth success` / `cancel` / `unavailable`: 端末の認証（Face ID など）の結果を決める（既定は success）。
///   UI テストからは Face ID の画面を操作できないため
enum UITestSupport {
    static let uiTestingArgument = "-ui-testing"
    static let seedArgument = "-ui-test-seed"
    static let authArgument = "-ui-test-auth"

    static func makeContainerIfRequested(arguments: [String] = ProcessInfo.processInfo.arguments) -> AppContainer? {
        guard arguments.contains(uiTestingArgument) else { return nil }
        let suiteName = "ui-testing"
        let defaults = UserDefaults(suiteName: suiteName)!
        defaults.removePersistentDomain(forName: suiteName)
        // 起動の引数で、レビューのお願いの段階・アプリを開いた回数を決めて起動できるようにする（レビューのお願い・アプリ起動広告の確かめ用）
        // 例: `-ui-test-review-stage DISLIKED`、`-ui-test-launch-count 9`（次に開くと10回目）、`-ui-test-liked-at 10`
        // 設定と同じ名前（`-app_launch_count` など）で渡すと、その起動の間はずっとその値が優先され、保存しても変わらなくなるので、別の名前にしている
        func argument(_ name: String) -> String? {
            arguments.firstIndex(of: name).flatMap { $0 + 1 < arguments.count ? arguments[$0 + 1] : nil }
        }
        if let stage = argument("-ui-test-review-stage") { defaults.set(stage, forKey: SettingsKeys.reviewStage) }
        if let count = argument("-ui-test-launch-count").flatMap(Int.init) { defaults.set(count, forKey: SettingsKeys.appLaunchCount) }
        if let likedAt = argument("-ui-test-liked-at").flatMap(Int.init) { defaults.set(likedAt, forKey: SettingsKeys.reviewLikedAtLaunch) }
        do {
            let database = try AppDatabase.makeInMemory()
            if let index = arguments.firstIndex(of: seedArgument), index + 1 < arguments.count {
                try seed(arguments[index + 1], into: database)
            }
            let auth = arguments.firstIndex(of: authArgument).flatMap { $0 + 1 < arguments.count ? arguments[$0 + 1] : nil }
            return AppContainer(database: database, defaults: defaults) { lockSession in
                UITestAuthenticator(lockSession: lockSession, result: auth ?? "success")
            }
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
        case "folders":
            try database.writer.write { db in
                // 更新日の新しい順: Hobby（中にメモ1件）→ Work（空）→ Recipes（中にフォルダ1つ）
                func folder(_ name: String, _ color: FolderColor, _ parent: Int64?, _ time: Int64) throws -> Int64 {
                    try FolderDao.insert(db, FolderRecord(
                        parentId: parent, name: name, colorKey: color.rawValue, createdAt: time, updatedAt: time))
                }
                let recipes = try folder("Recipes", .default, nil, base)
                _ = try folder("Sweets", .pink, recipes, base)
                _ = try folder("Work", .red, nil, base + hour)
                let hobby = try folder("Hobby", .blue, nil, base + 2 * hour)
                _ = try MemoDao.insert(db, MemoRecord(
                    folderId: hobby, html: "Books to read", plainText: "Books to read", firstLine: "Books to read",
                    charCount: 11, createdAt: base + 2 * hour, updatedAt: base + 2 * hour))
            }
        case "deep":
            // 5階層: Level 1 ＞ Level 2 ＞ … ＞ Level 5（5階層目の中にはフォルダを作れない）
            try database.writer.write { db in
                var parent: Int64?
                for level in 1...FolderPolicy.maxDepth {
                    parent = try FolderDao.insert(db, FolderRecord(
                        parentId: parent, name: "Level \(level)", colorKey: FolderColor.default.rawValue,
                        createdAt: base, updatedAt: base))
                }
            }
        case "trash":
            // ゴミ箱（削除日の新しい順）: Old note（メモタブのメモ）→ Travel（中にフォルダ Hotels とメモ Packing list）
            // → Itinerary（Travel の中のメモ。Travel より先に単体で削除したので、元のフォルダもゴミ箱にある）
            // 起動時に30日を過ぎたものが消されるので、削除日は今の時刻から決める
            let now = AppClock().now()
            try database.writer.write { db in
                func memo(_ text: String, folderId: Int64?, deletedAt: Int64, withFolder: Bool = false) throws {
                    _ = try MemoDao.insert(db, MemoRecord(
                        folderId: folderId, html: text, plainText: text, firstLine: text, charCount: CharCounter.countChars(text),
                        createdAt: base, updatedAt: base, deletedAt: deletedAt, deletedWithFolder: withFolder))
                }
                try memo("Old note", folderId: nil, deletedAt: now - hour)
                let travel = try FolderDao.insert(db, FolderRecord(
                    parentId: nil, name: "Travel", colorKey: FolderColor.green.rawValue, createdAt: base, updatedAt: base,
                    deletedAt: now - 2 * hour))
                _ = try FolderDao.insert(db, FolderRecord(
                    parentId: travel, name: "Hotels", colorKey: FolderColor.default.rawValue, createdAt: base, updatedAt: base,
                    deletedAt: now - 2 * hour, deletedWithParent: true))
                try memo("Packing list", folderId: travel, deletedAt: now - 2 * hour, withFolder: true)
                try memo("Itinerary", folderId: travel, deletedAt: now - 3 * hour)
            }
        case "locked":
            // ロックしたもの: Secret（メモタブのロックしたメモ）/ Note（ふつうのメモ）/ Private（ロックしたフォルダ。中にメモ Diary とフォルダ Inner）
            try database.writer.write { db in
                func memo(_ text: String, folderId: Int64?, locked: Bool, time: Int64) throws {
                    _ = try MemoDao.insert(db, MemoRecord(
                        folderId: folderId, html: text, plainText: text, firstLine: text, charCount: CharCounter.countChars(text),
                        createdAt: time, updatedAt: time, isLocked: locked))
                }
                try memo("Secret", folderId: nil, locked: true, time: base + hour)
                try memo("Note", folderId: nil, locked: false, time: base)
                let privateFolder = try FolderDao.insert(db, FolderRecord(
                    parentId: nil, name: "Private", colorKey: FolderColor.purple.rawValue, createdAt: base, updatedAt: base,
                    isLocked: true))
                _ = try FolderDao.insert(db, FolderRecord(
                    parentId: privateFolder, name: "Inner", colorKey: FolderColor.default.rawValue, createdAt: base, updatedAt: base))
                try memo("Diary", folderId: privateFolder, locked: false, time: base)
            }
        default:
            fatalError("知らないダミーデータ: \(name)")
        }
    }
}
/// UI テスト用の端末の認証。Face ID の画面を出さず、起動の引数で決めた結果を返す。
final class UITestAuthenticator: DeviceAuthenticator {
    private let result: String

    init(lockSession: LockSession, result: String) {
        self.result = result
        super.init(lockSession: lockSession)
    }

    override func isAvailable() -> Bool { result != "unavailable" }

    override func authenticate() async -> Bool { result == "success" }
}
#endif
