import SwiftUI

extension View {
    /// 「パスコードが必要です」の案内（iOS ではアプリから「Face ID とパスコード」の設定画面を開けないので、場所を文で伝えるだけ）。
    func passcodeRequiredAlert(isPresented: Binding<Bool>, onDismiss: @escaping () -> Void = {}) -> some View {
        alert("lock_passcode_required_title_ios", isPresented: isPresented) {
            Button("action_close", role: .cancel) { onDismiss() }
        } message: {
            Text("lock_passcode_required_message_ios")
        }
    }
}

/// 認証するまで中身の代わりに出す表示（「このメモはロックされています」など）。
struct LockedPlaceholder: View {
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "lock.fill")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text(message)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("locked_placeholder")
    }
}

/// アプリの切り替え画面に中身を映さないための覆い（起動画面と同じ見た目）。
struct PrivacyCover: View {
    var body: some View {
        LaunchCover().accessibilityIdentifier("privacy_cover")
    }
}

/// iOS の起動画面（Config/Info.plist の UILaunchScreen）と同じ見た目: 背景色とロゴ。
struct LaunchCover: View {
    var body: some View {
        ZStack {
            Color("LaunchBackground")
            Image("LaunchLogo")
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

/// ロックの付け外しの長押しメニューの項目（「ロックする」／「ロックを外す」）。
struct LockMenuButton: View {
    let isLocked: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(isLocked ? LocalizedStringKey("action_unlock") : "action_lock",
                  systemImage: isLocked ? "lock.open" : "lock")
        }
    }
}
