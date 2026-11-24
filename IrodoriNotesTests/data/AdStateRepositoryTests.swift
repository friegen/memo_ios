import Foundation
import Testing
@testable import IrodoriNotes

/// 広告とレビューのお願いの記録（UserDefaults。Android 版の AdStateRepositoryTest・ReviewRepositoryTest にあたる）。
struct AdStateRepositoryTests {

    @Test func launchCountAndLastShownAt() throws {
        let defaults = try makeTestDefaults()
        let repository = AdStateRepository(defaults: defaults)
        #expect(repository.launchCount == 0)
        #expect(repository.incrementLaunchCount() == 1)
        #expect(repository.incrementLaunchCount() == 2)
        #expect(defaults.integer(forKey: "app_launch_count") == 2) // Android と同じキー

        #expect(repository.appOpenAdLastShownAt == nil)
        repository.setAppOpenAdLastShownAt(1_763_251_200_000)
        #expect(repository.appOpenAdLastShownAt == 1_763_251_200_000)
    }

    /// フォルダの中に作れる残りの数: 増やす・使う（0 より下がらない）。
    @Test func subfolderCredits() throws {
        let repository = AdStateRepository(defaults: try makeTestDefaults())
        repository.consumeSubfolderCredit()
        #expect(repository.subfolderCredits == 0)
        repository.addSubfolderCredits(2)
        repository.consumeSubfolderCredit()
        #expect(repository.subfolderCredits == 1)
    }

    @Test func reviewState() throws {
        let defaults = try makeTestDefaults()
        let repository = ReviewRepository(defaults: defaults)
        #expect(repository.state == ReviewState())

        repository.setLiked(atLaunch: 10)
        #expect(repository.state == ReviewState(stage: .liked, likedAtLaunch: 10))
        #expect(defaults.string(forKey: "review_stage") == "LIKED") // Android と同じ値

        repository.setStage(.reviewAsked)
        #expect(repository.state.stage == .reviewAsked)

        defaults.set("UNKNOWN", forKey: "review_stage") // 知らない値は「まだ聞いていない」
        #expect(repository.state.stage == .notAsked)
    }

    /// アプリ起動広告を出してよいか: レビューの流れで出してよい段階 ＋ 前回から4時間以上。出したら記録する。
    @Test func shouldShowAppOpenAd() throws {
        let (container, _, clock) = try makeTestContainer(now: 100 * 60 * 60 * 1000)
        let shouldShow = container.makeShouldShowAppOpenAdUseCase()
        #expect(!shouldShow()) // まだ出してよい段階ではない

        container.reviewRepository.setStage(.disliked)
        #expect(shouldShow())

        container.makeRecordAppOpenAdShownUseCase()()
        #expect(!shouldShow())
        clock.nowValue += AdPolicy.appOpenIntervalMillis
        #expect(shouldShow())
    }
}
