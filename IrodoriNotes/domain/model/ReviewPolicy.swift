import Foundation

/// レビューのお願いの流れ（Android 版の ReviewPolicy と同じ。docs/requirements.md「レビューのお願い」）。値を変えるときはここだけ直す。
///
/// 1. アプリを開いた回数が `askFavoriteAtLaunch` 回になったら「気に入っていただけましたか？」と聞く
///    - 気に入った → お礼。さらに `askReviewAfterLikedLaunches` 回開いたら、レビューをお願いする（1回だけ。iOS は requestReview）
///    - いまひとつ → 改善を続けますとお伝えする
/// 2. アプリ起動広告は、「いまひとつ」を選んだ人と、レビューをお願いし終えた人にだけ出す
///    （それまでは出さない。気に入ってくれた人には、レビューをお願いするまで広告を控える）
/// 聞く・お願いする画面はステップ12で作る。ステップ11では、アプリ起動広告を出してよいかの判定にだけ使う。
nonisolated enum ReviewPolicy {
    /// 何回目にアプリを開いたときに「気に入っていただけましたか？」と聞くか。
    static let askFavoriteAtLaunch = 10

    /// 「気に入った」と答えてから何回開いたらレビューをお願いするか。
    static let askReviewAfterLikedLaunches = 20

    /// 今アプリを開いたときに出すお願い。
    static func prompt(for state: ReviewState, launchCount: Int) -> ReviewPrompt {
        switch state.stage {
        case .notAsked:
            return launchCount >= askFavoriteAtLaunch ? .askFavorite : .none
        case .liked:
            let likedAt = state.likedAtLaunch ?? launchCount
            return launchCount >= likedAt + askReviewAfterLikedLaunches ? .askReview : .none
        case .disliked, .reviewAsked:
            return .none
        }
    }

    /// アプリ起動広告を出してよい段階か。
    static func isAppOpenAdUnlocked(_ state: ReviewState) -> Bool {
        state.stage == .disliked || state.stage == .reviewAsked
    }
}

/// レビューのお願いの進み具合。rawValue は保存用（Android と同じ名前）。
nonisolated enum ReviewStage: String, CaseIterable, Sendable {
    /// まだ「気に入っていただけましたか？」と聞いていない（または答えずに閉じた）
    case notAsked = "NOT_ASKED"
    /// 「気に入った」と答えた（レビューのお願いはまだ）
    case liked = "LIKED"
    /// 「いまひとつ」と答えた
    case disliked = "DISLIKED"
    /// レビューをお願いした（レビューを書いたかどうかは分からない）
    case reviewAsked = "REVIEW_ASKED"
}

/// レビューのお願いの状態。
nonisolated struct ReviewState: Equatable, Sendable {
    var stage: ReviewStage = .notAsked
    /// 「気に入った」と答えたときの、アプリを開いた回数
    var likedAtLaunch: Int?
}

/// アプリを開いたときに出すお願い。
nonisolated enum ReviewPrompt: Equatable, Sendable {
    case none
    case askFavorite
    case askReview
}
