import Foundation
import Testing
import UIKit
@testable import IrodoriNotes

/// メイン画面の ViewModel（テーマ・レビューのお願い。Android 版の MainViewModelTest にあたる）。
struct MainViewModelTests {

    @Test func startsWithSavedThemeMode() throws {
        let (container, _, _) = try makeTestContainer()
        container.settingsRepository.setThemeMode(.dark)

        let viewModel = container.makeMainViewModel()

        #expect(viewModel.uiState.themeMode == .dark) // 最初の画面から保存しているテーマ
    }

    @Test func followsThemeModeChanges() async throws {
        let (container, _, _) = try makeTestContainer()
        let viewModel = container.makeMainViewModel()
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }

        container.settingsRepository.setThemeMode(.light)

        try await waitUntil { viewModel.uiState.themeMode == .light }
    }

    /// 10回目に開いたとき「気に入っていただけましたか？」。9回目までは何も出さない。
    @Test func asksFavoriteOnTenthLaunch() async throws {
        let (container, _, _) = try makeTestContainer()
        let viewModel = container.makeMainViewModel()
        var events = viewModel.events().makeAsyncIterator()
        for _ in 1...9 { viewModel.onAppOpened() }
        #expect(container.adStateRepository.launchCount == 9)

        viewModel.onAppOpened()
        #expect(await events.next() == .askFavorite)
    }

    /// 「気に入った」→ お礼。さらに20回開いたら、レビューのお願い（1回だけ）。その後はアプリ起動広告を出してよい。
    @Test func likedThenRequestsReviewOnce() async throws {
        let (container, _, _) = try makeTestContainer()
        let viewModel = container.makeMainViewModel()
        var events = viewModel.events().makeAsyncIterator()
        for _ in 1...10 { viewModel.onAppOpened() }
        #expect(await events.next() == .askFavorite)

        viewModel.onFavoriteAnswered(liked: true)
        #expect(await events.next() == .thankForLiking)
        #expect(container.reviewRepository.state == ReviewState(stage: .liked, likedAtLaunch: 10))
        #expect(!container.makeShouldShowAppOpenAdUseCase()()) // 気に入ってくれた人には、まだ広告を出さない

        for _ in 11...29 { viewModel.onAppOpened() }
        viewModel.onAppOpened() // 30回目
        #expect(await events.next() == .requestReview)
        #expect(container.reviewRepository.state.stage == .reviewAsked)
        #expect(container.makeShouldShowAppOpenAdUseCase()())

        viewModel.onAppOpened() // もうお願いしない
        viewModel.onFavoriteAnswered(liked: false) // 次のイベントを確かめるための目印
        #expect(await events.next() == .thankForFeedback)
    }

    /// 「いまひとつ」→ お礼。もう聞かず、次からアプリ起動広告を出してよい。
    @Test func dislikedIsNotAskedAgain() async throws {
        let (container, _, _) = try makeTestContainer()
        let viewModel = container.makeMainViewModel()
        var events = viewModel.events().makeAsyncIterator()
        for _ in 1...10 { viewModel.onAppOpened() }
        #expect(await events.next() == .askFavorite)

        viewModel.onFavoriteAnswered(liked: false)
        #expect(await events.next() == .thankForFeedback)
        #expect(container.reviewRepository.state.stage == .disliked)
        #expect(container.makeShouldShowAppOpenAdUseCase()())
        #expect(container.makeGetReviewPromptUseCase()() == .none)
    }

    @Test func themeModeMapsToInterfaceStyle() {
        #expect(ThemeMode.system.userInterfaceStyle == .unspecified)
        #expect(ThemeMode.light.userInterfaceStyle == .light)
        #expect(ThemeMode.dark.userInterfaceStyle == .dark)
    }
}

/// 条件が満たされるまで少しずつ待つ（最大 `timeout` 秒）。ViewModel が非同期で状態を変えるのを待つのに使う。
func waitUntil(timeout: Double = 3, _ condition: () -> Bool) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline {
            Issue.record("時間内に条件が満たされなかった")
            return
        }
        try await Task.sleep(for: .milliseconds(20))
    }
}
