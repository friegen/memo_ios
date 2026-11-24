import XCTest

/// 出力の UI テスト（Android 版の MemoEditActivityTest の出力の部分にあたる）。メモリ上の DB で動かす。
final class ExportUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-ui-test-seed", "memos", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
    }

    private func openMemo(_ text: String) {
        app.buttons.matching(identifier: "memo_row").matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch.tap()
        XCTAssertTrue(app.textViews["memo_text"].waitForExistence(timeout: 5))
    }

    /// 出力 → 形式（4つ）を選ぶ → ファイルを作って共有シートが出る。
    @MainActor
    func testExportShowsFormatsThenShareSheet() {
        openMemo("Shopping list")
        app.buttons["export_button"].tap()

        for format in ["PDF", "Image (PNG)", "Text (.txt)", "Text with formatting (HTML)"] {
            XCTAssertTrue(app.buttons[format].waitForExistence(timeout: 5), format)
        }
        app.buttons["PDF"].tap()

        // 共有シート（iOS の UIActivityViewController）
        XCTAssertTrue(app.otherElements["ActivityListView"].waitForExistence(timeout: 10))
    }

    /// 何も書いていないメモは出力しない（「出力する文字がありません」）。
    @MainActor
    func testEmptyMemoCannotBeExported() {
        app.buttons["add_button"].tap()
        XCTAssertTrue(app.textViews["memo_text"].waitForExistence(timeout: 5))
        if app.buttons["hide_keyboard_button"].waitForExistence(timeout: 3) {
            app.buttons["hide_keyboard_button"].tap() // キーボードが出ている間は、出力の代わりに「キーボードを閉じる」
        }
        app.buttons["export_button"].tap()
        XCTAssertTrue(app.staticTexts["There’s nothing to export."].waitForExistence(timeout: 5))
    }
}
