import XCTest

/// ロックの UI テスト（Android 版の LockTest にあたる）。メモリ上の DB で動かす。
/// 端末の認証（Face ID など）は UI テストから操作できないので、起動の引数 `-ui-test-auth` で結果を決める。
/// ダミーデータ（locked）: Secret（ロックしたメモ）/ Note / Private（ロックしたフォルダ。中に Inner と Diary）
final class LockUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    private func launch(auth: String = "success") {
        app = XCUIApplication()
        app.launchArguments += [
            "-ui-testing", "-ui-test-seed", "locked", "-ui-test-auth", auth, "-AppleLanguages", "(en)", "-AppleLocale", "en_US",
        ]
        app.launch()
    }

    private func memoRow(_ text: String) -> XCUIElement {
        app.buttons.matching(identifier: "memo_row").matching(NSPredicate(format: "label CONTAINS %@", text)).firstMatch
    }

    private func folderRow(_ name: String) -> XCUIElement {
        app.buttons.matching(identifier: "folder_row").matching(NSPredicate(format: "label CONTAINS %@", name)).firstMatch
    }

    /// 一覧ではロックしたメモに鍵のアイコン（読み上げは「Locked」）が付き、1行目は見える。
    @MainActor
    func testLockedMemoShowsIconInList() {
        launch()
        XCTAssertTrue(memoRow("Secret").waitForExistence(timeout: 5))
        XCTAssertTrue(memoRow("Secret").label.contains("Locked"))
        XCTAssertFalse(memoRow("Note").label.contains("Locked"))
    }

    /// 認証できたら本文が見える。
    @MainActor
    func testOpenLockedMemoAfterAuthentication() {
        launch(auth: "success")
        memoRow("Secret").tap()
        let textView = app.textViews["memo_text"]
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        XCTAssertEqual(textView.value as? String, "Secret")
        XCTAssertFalse(app.otherElements["locked_placeholder"].exists)
    }

    /// 認証をやめたら、メモは閉じる（一覧に戻る）。
    @MainActor
    func testCancelClosesLockedMemo() {
        launch(auth: "cancel")
        memoRow("Secret").tap()
        XCTAssertTrue(app.navigationBars["Notes"].waitForExistence(timeout: 5))
        XCTAssertTrue(memoRow("Secret").exists)
    }

    /// ロックしたフォルダ: 認証できたら中身が見え、中のフォルダ・メモはもう聞かずに開ける。
    @MainActor
    func testOpenLockedFolder() {
        launch(auth: "success")
        app.tabBars.buttons["Folders"].tap()
        XCTAssertTrue(folderRow("Private").label.contains("Locked"))
        folderRow("Private").tap()
        XCTAssertTrue(memoRow("Diary").waitForExistence(timeout: 5))
        XCTAssertTrue(folderRow("Inner").exists)

        memoRow("Diary").tap()
        let textView = app.textViews["memo_text"]
        XCTAssertTrue(textView.waitForExistence(timeout: 5))
        XCTAssertEqual(textView.value as? String, "Diary")
    }

    /// 認証をやめたら、フォルダに入らない（フォルダタブに戻る）。
    @MainActor
    func testCancelLeavesLockedFolder() {
        launch(auth: "cancel")
        app.tabBars.buttons["Folders"].tap()
        folderRow("Private").tap()
        XCTAssertTrue(app.navigationBars["Folders"].waitForExistence(timeout: 5))
        XCTAssertFalse(memoRow("Diary").exists)
    }

    /// 長押し →「ロックする」→ お知らせ・鍵のアイコン →「ロックを外す」（認証）→ 外れる。
    @MainActor
    func testLockAndUnlockFromMenu() {
        launch(auth: "success")
        memoRow("Note").press(forDuration: 1.0)
        app.buttons["Lock"].tap()
        XCTAssertTrue(app.staticTexts["Locked"].waitForExistence(timeout: 5))
        XCTAssertTrue(memoRow("Note").label.contains("Locked"))

        memoRow("Note").press(forDuration: 1.0)
        app.buttons["Unlock"].tap()
        XCTAssertTrue(app.staticTexts["Unlocked"].waitForExistence(timeout: 5))
        XCTAssertFalse(memoRow("Note").label.contains("Locked"))
    }

    /// 端末にパスコードがないときは、ロックせずに設定の場所を案内する。
    @MainActor
    func testLockWithoutPasscodeShowsGuide() {
        launch(auth: "unavailable")
        memoRow("Note").press(forDuration: 1.0)
        app.buttons["Lock"].tap()
        let alert = app.alerts["Passcode required"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        alert.buttons["Close"].tap()
        XCTAssertFalse(memoRow("Note").label.contains("Locked"))
    }

    /// パスコードがないときにロックしたメモを開こうとすると、案内を出して閉じる（メモは消えない）。
    @MainActor
    func testOpenLockedMemoWithoutPasscode() {
        launch(auth: "unavailable")
        memoRow("Secret").tap()
        let alert = app.alerts["Passcode required"]
        XCTAssertTrue(alert.waitForExistence(timeout: 5))
        XCTAssertTrue(app.otherElements["locked_placeholder"].exists || app.staticTexts["This note is locked."].exists)
        alert.buttons["Close"].tap()
        XCTAssertTrue(memoRow("Secret").waitForExistence(timeout: 5))
    }

    /// アプリから離れて戻ると、ロックしたメモを開き直す（認証して見える。ロックした中身はアプリの切り替え画面で覆う）。
    @MainActor
    func testReturningFromBackgroundAsksAgain() {
        launch(auth: "success")
        memoRow("Secret").tap()
        XCTAssertTrue(app.textViews["memo_text"].waitForExistence(timeout: 5))

        XCUIDevice.shared.press(.home)
        app.activate()

        XCTAssertTrue(app.textViews["memo_text"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textViews["memo_text"].value as? String, "Secret")
    }
}
