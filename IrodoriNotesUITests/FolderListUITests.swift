import XCTest

/// フォルダタブの UI テスト（Android 版の FolderListFragmentTest にあたる）。メモリ上の DB で動かす。
final class FolderListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(seed: String? = nil) {
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if let seed { app.launchArguments += ["-ui-test-seed", seed] }
        app.launch()
        app.tabBars.buttons["Folders"].tap()
    }

    private func rows() -> XCUIElementQuery { app.buttons.matching(identifier: "folder_row") }

    private func row(_ name: String) -> XCUIElement {
        rows().matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    private func rowNames() -> [String] {
        rows().allElementsBoundByIndex.map { row in
            row.label.components(separatedBy: ", ").first { $0 != "Pinned" && $0 != "Locked" } ?? ""
        }
    }

    @MainActor
    func testEmptyMessage() {
        launch()
        XCTAssertTrue(app.staticTexts["folder_list_empty"].waitForExistence(timeout: 10))
    }

    /// ＋ → 名前と色を選んで作成 → そのフォルダの中に移る → 戻るとフォルダタブに並んでいる。
    @MainActor
    func testCreateFolderOpensIt() {
        launch()
        app.buttons["add_button"].tap()
        let field = app.textFields["folder_name_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["folder_submit_button"].isEnabled) // 名前が空のあいだは作れない

        field.typeText("Travel")
        app.buttons["folder_color_teal"].tap()
        XCTAssertTrue(app.buttons["folder_color_teal"].isSelected)
        app.buttons["folder_submit_button"].tap()

        XCTAssertTrue(app.navigationBars["Travel"].waitForExistence(timeout: 5)) // 作ったフォルダの中
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(row("Travel").waitForExistence(timeout: 5))
    }

    @MainActor
    func testFoldersAreListedAndSortedByName() {
        launch(seed: "folders")
        XCTAssertTrue(row("Hobby").waitForExistence(timeout: 10))
        XCTAssertEqual(rowNames(), ["Hobby", "Work", "Recipes"]) // 更新日の新しい順
        XCTAssertTrue(row("Hobby").label.contains("1 item"))

        app.buttons["sort_button"].tap()
        app.buttons["Name (A to Z)"].tap()
        let expected = NSPredicate { _, _ in self.rowNames() == ["Hobby", "Recipes", "Work"] }
        wait(for: [expectation(for: expected, evaluatedWith: nil)], timeout: 5)
    }

    /// 長押し → 名前・色を変更 → 変わる。
    @MainActor
    func testEditFolder() {
        launch(seed: "folders")
        XCTAssertTrue(row("Work").waitForExistence(timeout: 10))
        row("Work").press(forDuration: 1.0)
        app.buttons["Rename / change color"].tap()

        let field = app.textFields["folder_name_field"]
        XCTAssertTrue(field.waitForExistence(timeout: 5))
        XCTAssertEqual(field.value as? String, "Work")
        XCTAssertTrue(app.buttons["folder_color_red"].isSelected)
        field.typeText(" items")
        app.buttons["folder_submit_button"].tap()

        XCTAssertTrue(row("Work items").waitForExistence(timeout: 5))
    }

    /// 空のフォルダは確認なしで削除して「元に戻す」。中身があれば確認してから削除。
    @MainActor
    func testDeleteFolders() {
        launch(seed: "folders")
        XCTAssertTrue(row("Work").waitForExistence(timeout: 10))

        row("Work").press(forDuration: 1.0)
        app.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Folder moved to trash"].waitForExistence(timeout: 5))
        app.buttons["undo_button"].tap()
        XCTAssertTrue(row("Work").waitForExistence(timeout: 5))

        row("Hobby").press(forDuration: 1.0)
        app.buttons["Delete"].tap()
        let alert = app.alerts["Delete this folder?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(alert.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "1 note")).firstMatch.exists)
        alert.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Folder moved to trash"].waitForExistence(timeout: 5))
        XCTAssertFalse(row("Hobby").exists)
    }

    @MainActor
    func testPinMovesFolderToTop() {
        launch(seed: "folders")
        XCTAssertTrue(row("Recipes").waitForExistence(timeout: 10))
        row("Recipes").press(forDuration: 1.0)
        app.buttons["Pin"].tap()

        let pinned = NSPredicate { _, _ in self.rowNames().first == "Recipes" }
        wait(for: [expectation(for: pinned, evaluatedWith: nil)], timeout: 5)
    }

    /// 行をタップするとフォルダの中へ。
    @MainActor
    func testOpenFolder() {
        launch(seed: "folders")
        XCTAssertTrue(row("Hobby").waitForExistence(timeout: 10))
        row("Hobby").tap()
        XCTAssertTrue(app.navigationBars["Hobby"].waitForExistence(timeout: 5))
    }
}
