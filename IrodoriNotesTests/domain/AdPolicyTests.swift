import Foundation
import Testing
@testable import IrodoriNotes

/// 広告の出し方の決まり（Android 版の AdPolicyTest と同じ内容）。
struct AdPolicyTests {
    private let hour: Int64 = 60 * 60 * 1000

    @Test func appOpenAd_notUnlockedByReviewFlow_isNotShown() {
        #expect(!AdPolicy.shouldShowAppOpenAd(isUnlocked: false, lastShownAt: nil, now: 0))
    }

    @Test func appOpenAd_firstTimeAfterUnlocked_isShown() {
        #expect(AdPolicy.shouldShowAppOpenAd(isUnlocked: true, lastShownAt: nil, now: 0))
    }

    @Test func appOpenAd_waitsFourHoursSinceLastShown() {
        let shownAt = 10 * hour
        #expect(!AdPolicy.shouldShowAppOpenAd(isUnlocked: true, lastShownAt: shownAt, now: shownAt + 4 * hour - 1))
        #expect(AdPolicy.shouldShowAppOpenAd(isUnlocked: true, lastShownAt: shownAt, now: shownAt + 4 * hour))
    }

    @Test func appOpenAd_clockMovedBack_isShown() {
        #expect(AdPolicy.shouldShowAppOpenAd(isUnlocked: true, lastShownAt: 10 * hour, now: 9 * hour))
    }

    @Test func rewardedFallback_offlineOrNoFill_createsWithoutAd() {
        #expect(AdPolicy.rewardedFallback(.network, isOnline: false) == .createWithoutAd)
        #expect(AdPolicy.rewardedFallback(.noFill, isOnline: true) == .createWithoutAd)
        #expect(AdPolicy.rewardedFallback(.other, isOnline: true) == .createWithoutAd)
        #expect(AdPolicy.rewardedFallback(.unavailable, isOnline: true) == .createWithoutAd)
    }

    /// オンラインなのに広告のサーバーにつながらない → 広告ブロックの可能性が高い。
    @Test func rewardedFallback_onlineButCannotReachAdServer_asksToDisableAdBlocker() {
        #expect(AdPolicy.rewardedFallback(.network, isOnline: true) == .askToDisableAdBlocker)
        #expect(AdPolicy.rewardedFallback(.internalError, isOnline: true) == .askToDisableAdBlocker)
    }

    /// AdMob のエラーの番号から理由へ（1: 在庫なし、2: 通信、11: 内部のエラー）。
    @Test func adLoadFailure_fromAdMobErrorCodes() {
        func error(_ code: Int) -> NSError { NSError(domain: "com.google.admob", code: code) }
        #expect(adLoadFailure(of: error(1)) == .noFill)
        #expect(adLoadFailure(of: error(2)) == .network)
        #expect(adLoadFailure(of: error(11)) == .internalError)
        #expect(adLoadFailure(of: error(5)) == .other)
        #expect(adLoadFailure(of: NSError(domain: NSURLErrorDomain, code: 2)) == .other)
    }

    /// 単体テストでは広告の SDK を動かさない。
    @Test func adsAreDisabledInTests() {
        #expect(!AdsAvailability.current.isEnabled)
    }
}

/// レビューのお願いの流れ（Android 版の ReviewPolicyTest と同じ内容）。
struct ReviewPolicyTests {

    @Test func asksFavoriteFromTenthLaunch() {
        let state = ReviewState()
        #expect(ReviewPolicy.prompt(for: state, launchCount: 9) == .none)
        #expect(ReviewPolicy.prompt(for: state, launchCount: 10) == .askFavorite)
        #expect(ReviewPolicy.prompt(for: state, launchCount: 11) == .askFavorite) // 答えずに閉じたら次もまた聞く
    }

    @Test func liked_asksReviewTwentyLaunchesLater_once() {
        let liked = ReviewState(stage: .liked, likedAtLaunch: 10)
        #expect(ReviewPolicy.prompt(for: liked, launchCount: 29) == .none)
        #expect(ReviewPolicy.prompt(for: liked, launchCount: 30) == .askReview)
        #expect(ReviewPolicy.prompt(for: ReviewState(stage: .reviewAsked), launchCount: 31) == .none)
    }

    @Test func disliked_isNeverAskedAgain() {
        #expect(ReviewPolicy.prompt(for: ReviewState(stage: .disliked), launchCount: 100) == .none)
    }

    @Test func appOpenAd_unlockedOnlyAfterDislikeOrReviewRequest() {
        #expect(!ReviewPolicy.isAppOpenAdUnlocked(ReviewState(stage: .notAsked)))
        #expect(!ReviewPolicy.isAppOpenAdUnlocked(ReviewState(stage: .liked, likedAtLaunch: 10)))
        #expect(ReviewPolicy.isAppOpenAdUnlocked(ReviewState(stage: .disliked)))
        #expect(ReviewPolicy.isAppOpenAdUnlocked(ReviewState(stage: .reviewAsked)))
    }
}
