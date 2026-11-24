import Foundation
import Testing
@testable import IrodoriNotes

/// ロックを外している状態（Android 版の LockSessionTest にあたる）と、ロックの付け外しの確認。
struct LockSessionTests {

    @Test func foldersStayUnlockedUntilLockedAgain() {
        let session = LockSession()
        #expect(session.areUnlocked([])) // 守るものがなければ外れている扱い
        #expect(!session.areUnlocked([1]))

        session.unlockFolders([1, 2])
        #expect(session.areUnlocked([1]))
        #expect(session.areUnlocked([1, 2]))
        #expect(!session.areUnlocked([1, 3]))

        session.lockFolder(1) // フォルダの画面を閉じた
        #expect(!session.areUnlocked([1]))
        #expect(session.areUnlocked([2]))
    }

    /// アプリから離れたら、すべてロックし直して generation が増える。
    @Test func enteringBackgroundLocksEverything() {
        let session = LockSession()
        session.unlockFolders([1])
        let before = session.generation

        session.onEnterBackground()

        #expect(session.generation == before + 1)
        #expect(!session.areUnlocked([1]))
    }

    /// 認証の画面を出している間は、アプリから離れた扱いにしない。
    @Test func authenticatingDoesNotLock() {
        let session = LockSession()
        session.unlockFolders([1])
        session.isAuthenticating = true

        session.onEnterBackground()

        #expect(session.generation == 0)
        #expect(session.areUnlocked([1]))
    }

    @Test func protectedScreensAreCounted() {
        let session = LockSession()
        session.acquireProtectedScreen()
        session.acquireProtectedScreen()
        session.releaseProtectedScreen()
        #expect(session.protectedScreenCount == 1)
        session.releaseProtectedScreen()
        session.releaseProtectedScreen() // 多く呼んでも 0 より下がらない
        #expect(session.protectedScreenCount == 0)
    }
}

/// 長押しの「ロックする／ロックを外す」の確認（端末の認証は結果を決めて返すものに差し替える）。
struct DeviceAuthenticatorTests {

    private final class FakeAuthenticator: DeviceAuthenticator {
        let available: Bool
        let succeeds: Bool
        private(set) var authenticateCount = 0

        init(available: Bool, succeeds: Bool) {
            self.available = available
            self.succeeds = succeeds
            super.init(lockSession: LockSession())
        }

        override func isAvailable() -> Bool { available }

        override func authenticate() async -> Bool {
            authenticateCount += 1
            return succeeds
        }
    }

    /// ロックするときは認証しない（パスコードがあれば、そのままロックする）。
    @Test func lockingNeedsOnlyPasscode() async {
        let authenticator = FakeAuthenticator(available: true, succeeds: false)
        #expect(await authenticator.confirmLockChange(currentlyLocked: false) == .apply(locked: true))
        #expect(authenticator.authenticateCount == 0)
    }

    /// パスコードがなければロックしない（ロックしても開けなくなるため）。
    @Test func lockingWithoutPasscodeShowsGuide() async {
        let authenticator = FakeAuthenticator(available: false, succeeds: true)
        #expect(await authenticator.confirmLockChange(currentlyLocked: false) == .passcodeRequired)
    }

    /// ロックを外すときは認証する。
    @Test func unlockingNeedsAuthentication() async {
        #expect(await FakeAuthenticator(available: true, succeeds: true).confirmLockChange(currentlyLocked: true) == .apply(locked: false))
        #expect(await FakeAuthenticator(available: true, succeeds: false).confirmLockChange(currentlyLocked: true) == .cancelled)
        #expect(await FakeAuthenticator(available: false, succeeds: true).confirmLockChange(currentlyLocked: true) == .passcodeRequired)
    }

    @Test func unlockResults() async {
        #expect(await FakeAuthenticator(available: true, succeeds: true).unlock() == .unlocked)
        #expect(await FakeAuthenticator(available: true, succeeds: false).unlock() == .cancelled)
        #expect(await FakeAuthenticator(available: false, succeeds: true).unlock() == .passcodeRequired)
    }
}
