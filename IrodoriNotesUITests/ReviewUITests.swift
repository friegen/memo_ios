import XCTest

/// レビューのお願いの UI テスト（Android 版の MainActivityTest のレビューの部分にあたる）。
/// 起動の引数 `-ui-test-launch-count 9` で「次に開くと10回目」にして起動する。
final class ReviewUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(launchCount: Int) {
        app = XCUIApplication()
        app.launchArguments += [
            "-ui-testing", "-ui-test-launch-count", "\(launchCount)", "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
        ]
        app.launch()
    }

    /// 10回目に開いたとき「気に入っていただけましたか？」→「気に入った」→ お礼。
    @MainActor
    func testTenthLaunchAsksFavorite_liked() {
        launch(launchCount: 9)
        let alert = app.alerts["Enjoying Irodori Notes?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["I like it"].tap()

        XCTAssertTrue(app.alerts.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Thank you!")).firstMatch
            .waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2))
    }

    /// 「いまひとつ」→ 改善を続けますのお礼。
    @MainActor
    func testTenthLaunchAsksFavorite_notReally() {
        launch(launchCount: 9)
        let alert = app.alerts["Enjoying Irodori Notes?"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Not really"].tap()

        XCTAssertTrue(app.alerts.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Thank you for your feedback")).firstMatch
            .waitForExistence(timeout: 5))
        app.alerts.buttons["OK"].tap()
    }

    /// 9回目までは何も出さない。
    @MainActor
    func testNinthLaunchAsksNothing() {
        launch(launchCount: 8)
        XCTAssertTrue(app.navigationBars["Notes"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.alerts.firstMatch.waitForExistence(timeout: 2))
    }
}
