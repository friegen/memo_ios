import Foundation

/// 今アプリ起動広告を出してよいか。レビューのお願いの流れで広告を出してよい段階になっていて（`ReviewPolicy`）、前回から4時間以上たっているとき（`AdPolicy`）。
final class ShouldShowAppOpenAdUseCase {
    private let adStateRepository: AdStateRepository
    private let reviewRepository: ReviewRepository
    private let clock: AppClock

    init(adStateRepository: AdStateRepository, reviewRepository: ReviewRepository, clock: AppClock) {
        self.adStateRepository = adStateRepository
        self.reviewRepository = reviewRepository
        self.clock = clock
    }

    func callAsFunction() -> Bool {
        AdPolicy.shouldShowAppOpenAd(
            isUnlocked: ReviewPolicy.isAppOpenAdUnlocked(reviewRepository.state),
            lastShownAt: adStateRepository.appOpenAdLastShownAt,
            now: clock.now())
    }
}
