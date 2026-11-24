import XCTest

/// ゴミ箱の UI テスト（Android 版の TrashFragmentTest にあたる）。メモリ上の DB で動かす。
/// ダミーデータ（trash）: Old note（メモタブのメモ）/ Travel（中にフォルダ1つとメモ1件）/ Itinerary（Travel の中のメモ。Travel もゴミ箱）
final class TrashUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-test-seed", "trash", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
        app.buttons["settings_trash"].tap()
    }

    private func row(_ text: String) -> XCUIElement {
        app.buttons.matching(identifier: "trash_row").matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    /// 削除日の新しい順に並び、元の場所・中身・上の階層もゴミ箱にあることが出る。
    @MainActor
    func testListShowsDetails() {
        XCTAssertTrue(row("Old note").waitForExistence(timeout: 5))
        XCTAssertTrue(row("Old note").label.contains("Notes tab"))
        XCTAssertTrue(row("Travel").label.contains("Folders tab"))
        XCTAssertTrue(row("Itinerary").label.contains("Its folder is also in the trash."))
        XCTAssertLessThan(row("Old note").frame.minY, row("Travel").frame.minY)
        XCTAssertLessThan(row("Travel").frame.minY, row("Itinerary").frame.minY)
    }

    /// 元に戻す → お知らせ → メモタブに戻っている。
    @MainActor
    func testRestoreMemo() {
        row("Old note").tap()
        app.buttons["Restore"].tap()
        XCTAssertTrue(app.staticTexts["Restored"].waitForExistence(timeout: 5))
        XCTAssertFalse(row("Old note").exists)

        app.tabBars.buttons["Notes"].tap()
        XCTAssertTrue(app.buttons.matching(identifier: "memo_row").matching(NSPredicate(format: "label CONTAINS %@", "Old note"))
            .firstMatch.waitForExistence(timeout: 5))
    }

    /// 元のフォルダもゴミ箱にあるメモ → 「フォルダごと復元しますか？」→ フォルダごと戻る。
    @MainActor
    func testRestoreMemoWithFolder() {
        XCTAssertTrue(row("Itinerary").waitForExistence(timeout: 5))
        row("Itinerary").tap()
        app.buttons["Restore"].tap()
        let alert = app.alerts["Restore with folder?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Restore"].tap()

        XCTAssertTrue(app.staticTexts["Restored"].waitForExistence(timeout: 5))
        XCTAssertFalse(row("Itinerary").exists)
        XCTAssertFalse(row("Travel").exists) // フォルダも戻った
        XCTAssertTrue(row("Old note").exists)
    }

    /// 完全に削除 → 中身の数を出して確認 → 消える。
    @MainActor
    func testDeleteFolderPermanently() {
        XCTAssertTrue(row("Travel").waitForExistence(timeout: 5))
        row("Travel").tap()
        app.buttons["Delete permanently"].tap()
        let alert = app.alerts["Delete permanently?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Travel")).firstMatch.exists)
        alert.buttons["Delete"].tap()

        XCTAssertTrue(app.staticTexts["Deleted permanently"].waitForExistence(timeout: 5))
        XCTAssertFalse(row("Travel").exists)
        XCTAssertFalse(row("Itinerary").exists) // 中のメモ（ゴミ箱内）も一緒に消える
    }

    /// ゴミ箱を空にする → 確認 → 「ゴミ箱は空です」。
    @MainActor
    func testEmptyTrash() {
        XCTAssertTrue(row("Old note").waitForExistence(timeout: 5))
        app.buttons["empty_trash_button"].tap()
        let alert = app.alerts["Empty the trash?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Empty"].tap()

        XCTAssertTrue(app.staticTexts["trash_empty"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["empty_trash_button"].isEnabled)
    }
}
