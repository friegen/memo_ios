import XCTest

/// シミュレーターでアプリを起動して確かめるテスト（Android の androidTest にあたる）。
final class LaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(language: String, locale: String) -> XCUIApplication {
        let app = XCUIApplication()
        // -ui-testing: メモリ上の DB で動かし、広告（同意の画面など）も使わない（シミュレーターのデータに触れないため）
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(\(language))", "-AppleLocale", locale]
        app.launch()
        return app
    }

    /// 下タブが3つあり、押すとそのタブの画面に切り替わる。
    @MainActor
    func testThreeTabsSwitchScreens() throws {
        let app = launch(language: "en", locale: "en_US")
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        XCTAssertEqual(tabBar.buttons.count, 3)

        // 最初はメモタブ
        XCTAssertTrue(app.navigationBars["Notes"].waitForExistence(timeout: 5))

        tabBar.buttons["Folders"].tap()
        XCTAssertTrue(app.navigationBars["Folders"].waitForExistence(timeout: 5))

        tabBar.buttons["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 5))

        tabBar.buttons["Notes"].tap()
        XCTAssertTrue(app.navigationBars["Notes"].waitForExistence(timeout: 5))
    }

    /// 日本語の端末ではタブ名も日本語。
    @MainActor
    func testTabsInJapanese() throws {
        let app = launch(language: "ja", locale: "ja_JP")
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
        XCTAssertTrue(tabBar.buttons["メモ"].exists)
        XCTAssertTrue(tabBar.buttons["フォルダ"].exists)
        XCTAssertTrue(tabBar.buttons["設定"].exists)
    }
}
