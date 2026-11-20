import XCTest

/// 書式パネルの UI テスト（Android 版の MemoEditActivityTest の書式の部分にあたる）。メモリ上の DB で動かす。
final class FormatUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    private var textView: XCUIElement { app.textViews["memo_text"] }

    /// 本文の n 行目（0から）の先頭の単語をダブルタップして選ぶ。
    private func selectWord(line: Int) {
        textView.coordinate(withNormalizedOffset: .zero)
            .withOffset(CGVector(dx: 30, dy: 26 + Double(line) * 23))
            .doubleTap()
    }

    private func isSelected(_ identifier: String) -> Bool {
        app.buttons[identifier].isSelected
    }

    private func openFormatPanel() {
        app.buttons["format_button"].tap()
        XCTAssertTrue(app.otherElements["format_panel"].waitForExistence(timeout: 5))
    }

    /// 書式ボタンでパネルが開閉する。× でも閉じる。
    @MainActor
    func testFormatButtonTogglesPanel() {
        app.buttons["add_button"].tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        openFormatPanel()
        XCTAssertTrue(app.buttons["color_red"].exists)
        app.buttons["format_button"].tap()
        XCTAssertFalse(app.otherElements["format_panel"].waitForExistence(timeout: 2))

        openFormatPanel()
        app.buttons["format_close_button"].tap()
        XCTAssertFalse(app.otherElements["format_panel"].waitForExistence(timeout: 2))
    }

    /// パネルを開いて太字＋赤を選んでから入力 → その書式で入る。パネルを閉じて入力 → 書式なし。
    /// 戻って開き直しても書式が残っている（HTML で保存して読み込める）。
    @MainActor
    func testTypingWithPanelStateAndReopen() {
        app.buttons["add_button"].tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        openFormatPanel()
        app.buttons["format_bold"].tap()
        app.buttons["color_red"].tap()
        XCTAssertTrue(isSelected("format_bold"))
        XCTAssertTrue(isSelected("color_red"))
        textView.typeText("Strong\n")
        app.buttons["format_close_button"].tap()
        textView.typeText("Plain")
        app.navigationBars.buttons.element(boundBy: 0).tap()

        // 開き直す
        app.buttons.matching(identifier: "memo_row").firstMatch.tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        openFormatPanel()

        selectWord(line: 0)
        XCTAssertTrue(app.staticTexts["6 characters selected"].waitForExistence(timeout: 5))
        XCTAssertTrue(isSelected("format_bold"))
        XCTAssertTrue(isSelected("color_red"))

        selectWord(line: 1)
        XCTAssertTrue(app.staticTexts["5 characters selected"].waitForExistence(timeout: 5))
        XCTAssertFalse(isSelected("format_bold"))
        XCTAssertTrue(isSelected("color_default"))
    }

    /// 文字を選んで、選んだまま太字を付け外しできる。
    @MainActor
    func testToggleStyleOnSelection() {
        app.buttons["add_button"].tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        textView.typeText("Hello")
        openFormatPanel()

        selectWord(line: 0)
        XCTAssertTrue(app.staticTexts["5 characters selected"].waitForExistence(timeout: 5))
        XCTAssertFalse(isSelected("format_underline"))
        app.buttons["format_underline"].tap()
        XCTAssertTrue(isSelected("format_underline"))
        app.buttons["format_underline"].tap() // 選んだまま外す
        XCTAssertFalse(isSelected("format_underline"))
        XCTAssertTrue(app.staticTexts["5 characters selected"].exists) // 選んだまま
    }
}
