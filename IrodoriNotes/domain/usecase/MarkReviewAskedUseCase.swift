import Foundation

/// レビューをお願いした（お願いは1回だけ。この後はアプリ起動広告を出す）。
final class MarkReviewAskedUseCase {
    private let reviewRepository: ReviewRepository

    init(reviewRepository: ReviewRepository) {
        self.reviewRepository = reviewRepository
    }

    func callAsFunction() {
        reviewRepository.setStage(.reviewAsked)
    }
}
