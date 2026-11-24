import Foundation

/// 広告（AdMob）の出し方の決まり（Android 版の AdPolicy と同じ値。docs/requirements.md「広告」）。値を変えるときはここだけ直す。
nonisolated enum AdPolicy {
    /// アプリ起動広告を前回出してから、次に出せるようになるまでの間隔（4時間）。
    static let appOpenIntervalMillis: Int64 = 4 * 60 * 60 * 1000

    /// 読み込んでおいたアプリ起動広告を出せる期限（Google の決まり。過ぎたら読み込み直す）。
    static let appOpenAdExpiryMillis: Int64 = 4 * 60 * 60 * 1000

    /// 起動画面と同じ見た目のまま広告の準備を待つ最大の時間。間に合わなければその回は出さない（待たせない）。
    static let appOpenColdStartWait: Duration = .seconds(3)

    /// リワード広告を1回見ると、フォルダの中に作れるフォルダの数。
    static let subfoldersPerReward = 2

    /// リワード広告の読み込みを待つ最大の時間。
    static let rewardedLoadTimeout: Duration = .seconds(15)

    /// アプリ起動広告を出してよいか。
    /// - Parameters:
    ///   - isUnlocked: レビューのお願いの流れで、広告を出してよい段階になったか（`ReviewPolicy.isAppOpenAdUnlocked`）
    ///   - lastShownAt: 前回アプリ起動広告を出した時刻（まだ出したことがなければ nil）
    static func shouldShowAppOpenAd(isUnlocked: Bool, lastShownAt: Int64?, now: Int64) -> Bool {
        guard isUnlocked else { return false }
        guard let lastShownAt, now >= lastShownAt else { return true } // 時計が戻された場合も出してよい
        return now - lastShownAt >= appOpenIntervalMillis
    }

    /// リワード広告を出せなかったときに、フォルダを作らせるか。
    /// - 広告を出せない状態（同意の確認の前など）・オフライン・広告の在庫なし → 広告なしで作れる
    /// - オンラインなのに広告のサーバーにつながらない → 広告ブロックの可能性が高いので、オフにするようお願いする
    static func rewardedFallback(_ failure: AdLoadFailure, isOnline: Bool) -> RewardedFallback {
        if failure == .unavailable || !isOnline { return .createWithoutAd }
        if failure == .network || failure == .internalError { return .askToDisableAdBlocker }
        return .createWithoutAd
    }
}

/// 広告を出せなかった理由。
nonisolated enum AdLoadFailure: Equatable, Sendable {
    /// 広告のサーバーにつながらない（オフライン、または広告ブロック）
    case network
    /// 出せる広告がない（在庫なし）
    case noFill
    /// 広告の仕組みの中のエラー（広告ブロックで起きることもある）
    case internalError
    /// そのほか（読み込みの時間切れ、表示の失敗など）
    case other
    /// 広告を使えない状態（同意の確認の前、広告を使わない環境など）
    case unavailable
}

/// リワード広告を出せなかったときの対応。
nonisolated enum RewardedFallback: Equatable, Sendable {
    case createWithoutAd
    case askToDisableAdBlocker
}

/// リワード広告を見た結果。
nonisolated enum RewardedAdResult: Equatable, Sendable {
    /// 最後まで見て特典をもらった
    case earned
    /// 途中で閉じた（特典なし）
    case dismissed
    /// 広告を出せなかった
    case failed(AdLoadFailure)
}
