import Foundation

/// レビューのお願いの進み具合（UserDefaults。Android 版の ReviewRepository にあたる）。
final class ReviewRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var state: ReviewState {
        ReviewState(
            stage: defaults.string(forKey: SettingsKeys.reviewStage).flatMap(ReviewStage.init(rawValue:)) ?? .notAsked,
            likedAtLaunch: (defaults.object(forKey: SettingsKeys.reviewLikedAtLaunch) as? NSNumber)?.intValue)
    }

    /// 「気に入った」と答えた（そのときの開いた回数を覚えて、そこから数える）。
    func setLiked(atLaunch launch: Int) {
        defaults.set(ReviewStage.liked.rawValue, forKey: SettingsKeys.reviewStage)
        defaults.set(launch, forKey: SettingsKeys.reviewLikedAtLaunch)
    }

    func setStage(_ stage: ReviewStage) {
        defaults.set(stage.rawValue, forKey: SettingsKeys.reviewStage)
    }
}
