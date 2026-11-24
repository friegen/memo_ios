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
    /// ストアのスクリーンショット用のサンプルデータの言語（`-ui-test-seed store -ui-test-store-lang ja`）
    private static var storeLanguage = "en"

    /// 編集画面で、開いたときに選ぶ段落（`-ui-test-select-paragraph 3`。ストアのスクリーンショットの「選んだ範囲の文字数」用）
    static var selectParagraph: Int? {
        let arguments = ProcessInfo.processInfo.arguments
        return arguments.firstIndex(of: "-ui-test-select-paragraph").flatMap { $0 + 1 < arguments.count ? Int(arguments[$0 + 1]) : nil }
    }

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
        // テーマ（`-ui-test-theme DARK`。ストアのスクリーンショット用）
        if let theme = argument("-ui-test-theme") { defaults.set(theme, forKey: SettingsKeys.themeMode) }
        storeLanguage = argument("-ui-test-store-lang") ?? "en"
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
        case "store":
            try seedStore(into: database)
        default:
            fatalError("知らないダミーデータ: \(name)")
        }
    }
}
extension UITestSupport {
    /// ストアのスクリーンショット用のサンプルデータ（`StoreSampleData`。Android 版のストアの画像と同じ文章・日付・ピン留め・ロック）。
    private static func seedStore(into database: AppDatabase) throws {
        guard let data = StoreSampleData.language(storeLanguage) else { fatalError("サンプルデータを読めない") }
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        func t(_ day: Int, _ hour: Int = 9, _ minute: Int = 30) -> Int64 {
            let date = calendar.date(from: DateComponents(year: 2026, month: 11, day: day, hour: hour, minute: minute))!
            return Int64(date.timeIntervalSince1970 * 1000)
        }
        try database.writer.write { db in
            @discardableResult
            func memo(_ html: String, folderId: Int64?, created: Int64, updated: Int64, pinned: Bool = false, locked: Bool = false) throws -> Int64 {
                let plain = MemoHtml.toPlainText(html)
                let id = try MemoDao.insert(db, MemoRecord(
                    folderId: folderId, html: html, plainText: plain,
                    firstLine: CharCounter.firstLine(plain, maxChars: MemoPolicy.firstLineMaxChars),
                    charCount: CharCounter.countChars(plain), createdAt: created, updatedAt: updated,
                    isLocked: locked, isPinned: pinned))
                if let folderId { try FolderDao.touchWithAncestors(db, folderIds: [folderId], now: updated) }
                return id
            }
            func folder(_ name: String, _ color: FolderColor, parent: Int64?, time: Int64, pinned: Bool = false, locked: Bool = false) throws -> Int64 {
                let id = try FolderDao.insert(db, FolderRecord(
                    parentId: parent, name: name, colorKey: color.rawValue, createdAt: time, updatedAt: time,
                    isLocked: locked, isPinned: pinned))
                if let parent { try FolderDao.touchWithAncestors(db, folderIds: [parent], now: time) }
                return id
            }
            // メモタブ
            for item in data.memos {
                let created = t(item.created, 8 + item.created % 9)
                let updated = t(item.updated, 10 + item.updated % 9, 15)
                try memo(item.html, folderId: nil, created: created, updated: updated, pinned: item.pinned)
            }
            try memo(data.locked, folderId: nil, created: t(3), updated: t(12, 21, 5), locked: true)
            // フォルダタブ（0: 仕事〔ピン留め〕、最後: 日記〔ロック〕）
            let colors: [FolderColor] = [.blue, .green, .orange, .purple, .yellow, .pink]
            var folderIds: [Int64] = []
            for (i, name) in data.folders.enumerated() {
                folderIds.append(try folder(name, colors[i], parent: nil, time: t(2 + i, 9 + i),
                                            pinned: i == 0, locked: i == data.folders.count - 1))
            }
            for (i, name) in data.work.enumerated() {
                let child = try folder(name, i == 0 ? .teal : .default, parent: folderIds[0], time: t(5 + i, 13))
                for j in 0..<(3 - i) { try memo("memo", folderId: child, created: t(5 + i, 14 + j), updated: t(5 + i, 14 + j)) }
            }
            for (i, name) in data.hobby.enumerated() {
                _ = try folder(name, i == 0 ? .yellow : .orange, parent: folderIds[1], time: t(6 + i, 19))
            }
            for (i, html) in data.workMemos.enumerated() {
                try memo(html, folderId: folderIds[0], created: t(8 + i, 11), updated: t(14 + i, 16, 40))
            }
            // ほかのフォルダにもメモを入れて、件数が 0 ばかりにならないようにする
            for (index, count) in [(2, 4), (3, 3), (4, 2), (5, 6)] {
                // フォルダを作った日より後の日付にする（更新日が作成日より前にならないように）
                for i in 0..<count { try memo("memo \(i)", folderId: folderIds[index], created: t(8 + i, 8), updated: t(8 + i, 8)) }
            }
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
