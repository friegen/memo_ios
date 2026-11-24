import XCTest

/// 設定タブの UI テスト（Android 版の SettingsFragmentTest などにあたる）。メモリ上の DB・別の保存先の設定で動かす。
final class SettingsUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments += ["-ui-testing", "-AppleLanguages", "(en)", "-AppleLocale", "en_US"]
        app.launch()
        app.tabBars.buttons["Settings"].tap()
    }

    /// テーマはこの画面で直接切り替える（最初は「端末に従う」）。
    @MainActor
    func testThemeSwitch() {
        let picker = app.segmentedControls["theme_picker"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        XCTAssertTrue(picker.buttons["System"].isSelected)

        picker.buttons["Dark"].tap()
        XCTAssertTrue(picker.buttons["Dark"].isSelected)
        XCTAssertFalse(picker.buttons["System"].isSelected)
    }

    /// 「表示」: スライダーで段階を選ぶと、段階の名前が変わる。
    @MainActor
    func testDisplaySettings() {
        app.buttons["settings_display"].tap()
        XCTAssertTrue(app.staticTexts["Medium"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Normal"].exists)
        XCTAssertTrue(app.textViews["settings_sample_text"].exists)

        // 読み上げ用に段階の名前（「Medium」など）を値にしているので、adjust（値を数として読む）ではなく、つまみを指でずらす
        drag(app.sliders.element(boundBy: 0), from: 1.0 / 3, to: 1)
        XCTAssertTrue(app.staticTexts["Extra large"].waitForExistence(timeout: 5))
        drag(app.sliders.element(boundBy: 1), from: 1.0 / 3, to: 0)
        XCTAssertTrue(app.staticTexts["Narrow"].waitForExistence(timeout: 5))
    }

    /// スライダーのつまみ（`from` の位置。0 = 左端、1 = 右端）を `to` の位置までずらす。
    private func drag(_ slider: XCUIElement, from: Double, to: Double) {
        let start = slider.coordinate(withNormalizedOffset: CGVector(dx: from, dy: 0.5))
        let end = slider.coordinate(withNormalizedOffset: CGVector(dx: to, dy: 0.5))
        start.press(forDuration: 0.1, thenDragTo: end)
    }

    /// 「データ」: 今のデータサイズとバックアップの説明が出る。
    @MainActor
    func testDataSettings() {
        app.buttons["settings_data"].tap()
        XCTAssertTrue(app.staticTexts["data_size"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "iCloud Backup")).firstMatch.exists)
    }

    /// 「オープンソースライセンス」→ ライブラリ → ライセンスの全文。
    @MainActor
    func testLicenses() {
        app.buttons["settings_licenses"].tap()
        let row = app.buttons.matching(identifier: "license_row").matching(NSPredicate(format: "label CONTAINS %@", "GRDB")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        XCTAssertTrue(row.label.contains("MIT License"))
        row.tap()

        let text = app.staticTexts["license_text"]
        XCTAssertTrue(text.waitForExistence(timeout: 5))
        XCTAssertTrue(text.label.contains("Permission is hereby granted"))
    }
}
