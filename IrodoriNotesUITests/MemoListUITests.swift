import XCTest

/// メモタブの UI テスト（Android 版の MemoListFragmentTest にあたる）。
/// メモリ上の DB で動かすので、シミュレーターに入っているメモには触れない。
final class MemoListUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(seed: String? = nil) {
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        if let seed { app.launchArguments += ["-ui-test-seed", seed] }
        app.launch()
    }

    /// 一覧の行の1行目（上から順）。行の読み上げの文は「(Pinned, )1行目, 作成日…, 文字数」なので、ピンの印を除いて先頭を取る。
    private func rowTitles() -> [String] {
        app.buttons.matching(identifier: "memo_row").allElementsBoundByIndex.map { row in
            row.label.components(separatedBy: ", ").first { $0 != "Pinned" && $0 != "Locked" } ?? ""
        }
    }

    private func row(containing text: String) -> XCUIElement {
        app.buttons.matching(identifier: "memo_row").matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    @MainActor
    func testEmptyMessageWhenNoMemos() {
        launch()
        XCTAssertTrue(app.staticTexts["memo_list_empty"].waitForExistence(timeout: 10))
    }

    @MainActor
    func testMemosAreListedNewestUpdatedFirst() {
        launch(seed: "memos")
        XCTAssertTrue(row(containing: "Shopping list").waitForExistence(timeout: 10))
        XCTAssertEqual(rowTitles(), ["Shopping list", "Ideas", "Meeting notes"])
        XCTAssertFalse(app.staticTexts["memo_list_empty"].exists)
    }

    @MainActor
    func testSortByCharacters() {
        launch(seed: "memos")
        XCTAssertTrue(row(containing: "Shopping list").waitForExistence(timeout: 10))

        app.buttons["sort_button"].tap()
        app.buttons["Characters (fewest first)"].tap()

        let expected = ["Ideas", "Meeting notes", "Shopping list"]
        let predicate = NSPredicate { _, _ in self.rowTitles() == expected }
        wait(for: [expectation(for: predicate, evaluatedWith: nil)], timeout: 5)
    }

    @MainActor
    func testDeleteAndUndo() {
        launch(seed: "memos")
        let target = row(containing: "Ideas")
        XCTAssertTrue(target.waitForExistence(timeout: 10))

        target.press(forDuration: 1.0)
        app.buttons["Delete"].tap()

        XCTAssertTrue(app.otherElements["undo_banner"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Moved to trash"].exists)
        XCTAssertFalse(row(containing: "Ideas").exists)

        app.buttons["undo_button"].tap()
        XCTAssertTrue(row(containing: "Ideas").waitForExistence(timeout: 5))
        XCTAssertEqual(rowTitles(), ["Shopping list", "Ideas", "Meeting notes"])
    }

    @MainActor
    func testPinMovesMemoToTop() {
        launch(seed: "memos")
        let target = row(containing: "Meeting notes")
        XCTAssertTrue(target.waitForExistence(timeout: 10))

        target.press(forDuration: 1.0)
        app.buttons["Pin"].tap()

        let predicate = NSPredicate { _, _ in self.rowTitles().first == "Meeting notes" }
        wait(for: [expectation(for: predicate, evaluatedWith: nil)], timeout: 5)
        XCTAssertTrue(row(containing: "Meeting notes").label.contains("Pinned"))

        // ピン留めを外すと元の位置に戻る
        row(containing: "Meeting notes").press(forDuration: 1.0)
        app.buttons["Unpin"].tap()
        let back = NSPredicate { _, _ in self.rowTitles() == ["Shopping list", "Ideas", "Meeting notes"] }
        wait(for: [expectation(for: back, evaluatedWith: nil)], timeout: 5)
    }

    @MainActor
    func testOpenEditorFromRowAndAddButton() {
        launch(seed: "memos")
        let target = row(containing: "Ideas")
        XCTAssertTrue(target.waitForExistence(timeout: 10))

        target.tap()
        XCTAssertTrue(app.otherElements["memo_editor"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.tabBars.firstMatch.isHittable) // 編集画面では下タブを隠す
        app.navigationBars.buttons.firstMatch.tap() // 戻る

        XCTAssertTrue(app.buttons["add_button"].waitForExistence(timeout: 5))
        app.buttons["add_button"].tap()
        XCTAssertTrue(app.otherElements["memo_editor"].waitForExistence(timeout: 5))
    }
}
