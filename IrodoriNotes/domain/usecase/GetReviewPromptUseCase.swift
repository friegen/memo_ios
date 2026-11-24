import Foundation

/// 今アプリを開いたときに出すお願い（「気に入っていただけましたか？」・レビューのお願い・なし）。
final class GetReviewPromptUseCase {
    private let adStateRepository: AdStateRepository
    private let reviewRepository: ReviewRepository

    init(adStateRepository: AdStateRepository, reviewRepository: ReviewRepository) {
        self.adStateRepository = adStateRepository
        self.reviewRepository = reviewRepository
    }

    func callAsFunction() -> ReviewPrompt {
        ReviewPolicy.prompt(for: reviewRepository.state, launchCount: adStateRepository.launchCount)
    }
}
