import XCTest

/// フォルダの中の UI テスト（Android 版の FolderDetailFragmentTest にあたる）。メモリ上の DB で動かす。
final class FolderDetailUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(seed: String) {
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-test-seed", seed, "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.tabBars.buttons["Folders"].tap()
    }

    private func folderRow(_ name: String) -> XCUIElement {
        app.buttons.matching(identifier: "folder_row").matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    private func memoRow(_ text: String) -> XCUIElement {
        app.buttons.matching(identifier: "memo_row").matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func staticText(containing text: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// フォルダが上・メモが下。＋の「新しいメモ」でこのフォルダにメモを作れる。
    @MainActor
    func testFoldersAboveMemosAndAddMemo() {
        launch(seed: "folders")
        folderRow("Recipes").tap()
        XCTAssertTrue(folderRow("Sweets").waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Recipes"].exists)

        app.buttons["add_button"].tap()
        app.buttons["New note"].tap()
        let textView = app.textViews["memo_text"]
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        textView.typeText("Pancakes")
        goBack()

        XCTAssertTrue(memoRow("Pancakes").waitForExistence(timeout: 5))
        XCTAssertLessThan(folderRow("Sweets").frame.minY, memoRow("Pancakes").frame.minY) // フォルダが上
    }

    /// ＋の「新しいフォルダ」→ 広告の説明 →「広告を見る」→ 作るとその中へ移り、サブタイトルに上の階層が出る。
    @MainActor
    func testAddFolderOpensItWithPath() {
        launch(seed: "folders")
        folderRow("Hobby").tap()
        XCTAssertTrue(memoRow("Books to read").waitForExistence(timeout: 5))

        app.buttons["add_button"].tap()
        app.buttons["New folder"].tap()
        // フォルダの中にフォルダを作るときはリワード広告の説明が出る（UI テストでは広告を使わないので、広告なしで作れる）
        let offer = app.alerts["Create a folder inside a folder"]
        XCTAssertTrue(offer.waitForExistence(timeout: 5))
        offer.buttons["Watch ad"].tap()
        let field = app.textFields["folder_name_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        field.typeText("Reading")
        app.buttons["folder_submit_button"].tap()

        XCTAssertTrue(app.staticTexts["Reading"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Hobby"].waitForExistence(timeout: 5)) // サブタイトルに上の階層
        XCTAssertTrue(app.staticTexts["folder_detail_empty"].waitForExistence(timeout: 5))
    }

    /// 2階層目以降のサブタイトルは「Level 1 › Level 2 …」。5階層目では「新しいフォルダ」を押せない。
    @MainActor
    func testDeepestLevelCannotCreateFolder() {
        launch(seed: "deep")
        for level in 1...5 {
            let row = folderRow("Level \(level)")
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.tap()
        }
        XCTAssertTrue(app.staticTexts["Level 1 › Level 2 › Level 3 › Level 4"].waitForExistence(timeout: 5))

        app.buttons["add_button"].tap()
        XCTAssertTrue(app.buttons["New note"].isEnabled)
        XCTAssertFalse(app.buttons["New folder"].isEnabled)
    }

    /// メモを長押し →「別のフォルダへ移動」→ 移動先 → 移る（お知らせが出る）。
    @MainActor
    func testMoveMemo() {
        launch(seed: "folders")
        folderRow("Hobby").tap()
        let memo = memoRow("Books to read")
        XCTAssertTrue(memo.waitForExistence(timeout: 5))

        memo.press(forDuration: 1.0)
        app.buttons["Move to another folder"].tap()
        let targets = app.buttons.matching(identifier: "move_target")
        XCTAssertTrue(targets.firstMatch.waitForExistence(timeout: 5))
        let current = targets.matching(NSPredicate(format: "label CONTAINS %@", "Hobby")).firstMatch
        XCTAssertFalse(current.isEnabled) // 今いるフォルダは選べない
        targets.matching(NSPredicate(format: "label CONTAINS %@", "Work")).firstMatch.tap()

        XCTAssertTrue(staticText(containing: "Moved to").waitForExistence(timeout: 5))
        XCTAssertFalse(memo.exists)
        goBack()
        folderRow("Work").tap()
        XCTAssertTrue(memoRow("Books to read").waitForExistence(timeout: 5))
    }

    /// フォルダの中で別のタブ → フォルダタブに戻ると、フォルダタブのトップ（Android 版 v1.8）。
    @MainActor
    func testSwitchingTabsReturnsToTop() {
        launch(seed: "deep")
        folderRow("Level 1").tap()
        folderRow("Level 2").tap()
        XCTAssertTrue(app.staticTexts["Level 2"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Notes"].tap()
        app.tabBars.buttons["Folders"].tap()
        XCTAssertTrue(app.navigationBars["Folders"].waitForExistence(timeout: 5))
        XCTAssertTrue(folderRow("Level 1").exists)
    }

    /// 今いるタブ（フォルダタブ）をもう一度押しても、トップに戻る。
    @MainActor
    func testTappingCurrentTabReturnsToTop() {
        launch(seed: "deep")
        folderRow("Level 1").tap()
        folderRow("Level 2").tap()
        XCTAssertTrue(app.staticTexts["Level 2"].waitForExistence(timeout: 5))

        app.tabBars.buttons["Folders"].tap()
        XCTAssertTrue(app.navigationBars["Folders"].waitForExistence(timeout: 5))
    }
}
