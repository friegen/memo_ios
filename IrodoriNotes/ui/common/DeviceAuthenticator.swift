import LocalAuthentication

/// 端末の認証（Face ID / Touch ID。だめなら端末のパスコード）。メモ・フォルダのロックに使う（Android 版の DeviceAuthenticator にあたる）。
///
/// アプリ独自のパスワードは使わない（忘れたら開けなくなるため）。端末のパスコードで必ず開けるので、忘れる心配がない。
/// UI テストでは認証の画面を操作できないので、結果を決めて返すもの（`UITestSupport`）に差し替える（そのため final にしない）。
class DeviceAuthenticator {
    private let lockSession: LockSession

    init(lockSession: LockSession) {
        self.lockSession = lockSession
    }

    /// 認証できる状態か（端末にパスコードが設定されている）。
    func isAvailable() -> Bool {
        LAContext().canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
    }

    /// 認証の画面を出す。認証できたら true、キャンセルなどで閉じたら false。
    func authenticate() async -> Bool {
        lockSession.isAuthenticating = true
        defer { lockSession.isAuthenticating = false }
        do {
            // パスコードの画面で出る説明（Face ID の画面では出ない）
            return try await LAContext().evaluatePolicy(.deviceOwnerAuthentication, localizedReason: L10n.string("lock_auth_title"))
        } catch {
            return false
        }
    }

    /// ロックを外すための認証（ロックしたメモを開く・ロックしたフォルダに入る・ロックを外す）。
    func unlock() async -> UnlockResult {
        guard isAvailable() else { return .passcodeRequired }
        return await authenticate() ? .unlocked : .cancelled
    }

    /// 長押しメニューの「ロックする／ロックを外す」。外すときは認証してから、ロックするときはパスコードがあるか確かめてから
    /// （パスコードがないとロックしても開けなくなるため）。
    func confirmLockChange(currentlyLocked: Bool) async -> LockChangeResult {
        if currentlyLocked {
            switch await unlock() {
            case .unlocked: return .apply(locked: false)
            case .cancelled: return .cancelled
            case .passcodeRequired: return .passcodeRequired
            }
        }
        return isAvailable() ? .apply(locked: true) : .passcodeRequired
    }
}

/// ロックを外す認証の結果。
enum UnlockResult: Equatable {
    case unlocked
    case cancelled
    /// 端末にパスコードがない（設定するよう案内する。ロックしたものは消えず、設定し直せば開ける）
    case passcodeRequired
}

/// 「ロックする／ロックを外す」を確かめた結果。
enum LockChangeResult: Equatable {
    case apply(locked: Bool)
    case cancelled
    case passcodeRequired
}
