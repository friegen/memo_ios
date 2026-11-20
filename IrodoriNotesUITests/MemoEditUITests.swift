import XCTest

/// メモ編集画面の UI テスト（Android 版の MemoEditActivityTest にあたる）。メモリ上の DB で動かす。
final class MemoEditUITests: XCTestCase {
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

    private var textView: XCUIElement { app.textViews["memo_text"] }

    private func row(containing text: String) -> XCUIElement {
        app.buttons.matching(identifier: "memo_row").matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func goBack() {
        app.navigationBars.buttons.element(boundBy: 0).tap()
    }

    /// ＋で新規作成 → 入力すると文字数・行数が出る → 戻ると一覧に出る。
    @MainActor
    func testCreateMemo() {
        launch()
        app.buttons["add_button"].tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))

        textView.typeText("Hello\nWorld")

        XCTAssertTrue(app.staticTexts["10 characters"].waitForExistence(timeout: 5)) // 改行は数えない
        XCTAssertTrue(app.staticTexts["2 lines"].exists)
        goBack()

        XCTAssertTrue(row(containing: "Hello").waitForExistence(timeout: 5))
        XCTAssertTrue(row(containing: "Hello").label.contains("10"))
    }

    /// 何も書かずに戻ると、メモは増えない。
    @MainActor
    func testNewMemoWithoutTextIsNotSaved() {
        launch()
        app.buttons["add_button"].tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        goBack()

        XCTAssertTrue(app.staticTexts["memo_list_empty"].waitForExistence(timeout: 5))
    }

    /// 既存のメモを開いて編集すると、一覧の1行目が変わる。
    @MainActor
    func testEditExistingMemo() {
        launch(seed: "memos")
        row(containing: "Ideas").tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        XCTAssertEqual(textView.value as? String, "Ideas")

        focusAtEnd()
        textView.typeText(" and plans")
        goBack()

        XCTAssertTrue(row(containing: "Ideas and plans").waitForExistence(timeout: 5))
    }

    /// 開いたときからあるメモを空にして戻る → 確認ダイアログ（編集に戻る／元に戻して閉じる／削除する）。
    @MainActor
    func testEmptiedMemoAsksBeforeLeaving() {
        launch(seed: "memos")
        row(containing: "Ideas").tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        clear()

        // 編集に戻る → 画面に残る
        app.buttons["editor_back_button"].tap()
        XCTAssertTrue(app.alerts["This note is empty"].waitForExistence(timeout: 5))
        app.alerts.buttons["Keep editing"].tap()
        XCTAssertTrue(textView.exists)

        // 元に戻して閉じる → 一覧に元のまま残る
        app.buttons["editor_back_button"].tap()
        app.alerts.buttons["Revert and close"].tap()
        XCTAssertTrue(row(containing: "Ideas").waitForExistence(timeout: 5))

        // もう一度空にして、削除する → ゴミ箱へ（お知らせが出る）
        row(containing: "Ideas").tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        clear()
        app.buttons["editor_back_button"].tap()
        app.alerts.buttons["Delete"].tap()
        XCTAssertTrue(app.staticTexts["Moved to trash"].waitForExistence(timeout: 5))
        XCTAssertFalse(row(containing: "Ideas").exists)
    }

    /// 空にしたメモは、左端からのスワイプで戻ろうとしても確認ダイアログを出す。
    @MainActor
    func testSwipeBackOnEmptiedMemoAsks() {
        launch(seed: "memos")
        row(containing: "Ideas").tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        clear()

        let window = app.windows.firstMatch
        let start = window.coordinate(withNormalizedOffset: CGVector(dx: 0.01, dy: 0.5))
        start.press(forDuration: 0.05, thenDragTo: window.coordinate(withNormalizedOffset: CGVector(dx: 0.7, dy: 0.5)))

        XCTAssertTrue(app.alerts["This note is empty"].waitForExistence(timeout: 5))
        app.alerts.buttons["Keep editing"].tap()
    }

    /// キーボードが出ている間だけ「キーボードを閉じる」ボタンが出る（ソフトウェアキーボードが出る設定のときだけ確かめる）。
    @MainActor
    func testHideKeyboardButton() {
        launch()
        app.buttons["add_button"].tap()
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        guard app.keyboards.firstMatch.waitForExistence(timeout: 3) else { return }

        XCTAssertTrue(app.buttons["hide_keyboard_button"].waitForExistence(timeout: 3))
        app.buttons["hide_keyboard_button"].tap()
        XCTAssertFalse(app.keyboards.firstMatch.waitForExistence(timeout: 2))
        XCTAssertFalse(app.buttons["hide_keyboard_button"].exists)
    }

    /// 本文の下の空いているところをタップして、カーソルを末尾に置く。
    private func focusAtEnd() {
        textView.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.9)).tap()
    }

    /// 本文をすべて消す。
    private func clear() {
        focusAtEnd()
        let length = (textView.value as? String)?.count ?? 0
        textView.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: length + 2))
    }
}
