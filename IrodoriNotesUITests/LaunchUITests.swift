import XCTest

/// シミュレーターでアプリを起動して確かめるテスト（Android の androidTest にあたる）。
final class LaunchUITests: XCTestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    @MainActor
    func testLaunchShowsAppName() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        XCTAssertTrue(app.staticTexts["root_title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["root_title"].label, "Irodori Notes")
    }

    @MainActor
    func testLaunchInJapanese() throws {
        let app = XCUIApplication()
        app.launchArguments += ["-AppleLanguages", "(ja)", "-AppleLocale", "ja_JP"]
        app.launch()
        XCTAssertTrue(app.staticTexts["root_title"].waitForExistence(timeout: 10))
        XCTAssertEqual(app.staticTexts["root_title"].label, "いろどりメモ")
    }
}
