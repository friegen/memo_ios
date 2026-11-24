import Foundation

/// 「気に入っていただけましたか？」の答えを記録する。
final class AnswerFavoriteUseCase {
    private let adStateRepository: AdStateRepository
    private let reviewRepository: ReviewRepository

    init(adStateRepository: AdStateRepository, reviewRepository: ReviewRepository) {
        self.adStateRepository = adStateRepository
        self.reviewRepository = reviewRepository
    }

    func callAsFunction(liked: Bool) {
        if liked {
            reviewRepository.setLiked(atLaunch: adStateRepository.launchCount)
        } else {
            reviewRepository.setStage(.disliked)
        }
    }
}
