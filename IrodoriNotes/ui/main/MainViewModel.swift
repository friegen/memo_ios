import Foundation
import Observation

/// メイン画面（下タブ）の状態。
struct MainUiState: Equatable {
    var themeMode: ThemeMode
}

/// メイン画面の一回きりのイベント（レビューのお願い）。
enum MainEvent: Equatable, Sendable {
    /// 「いろどりメモはいかがですか？ 気に入っていただけましたか？」
    case askFavorite
    /// 「気に入った」へのお礼
    case thankForLiking
    /// 「いまひとつ」へのお礼（改善を続けますとお伝えする）
    case thankForFeedback
    /// レビューのお願い（iOS の requestReview。出すかどうかは iOS が決める）
    case requestReview
}

/// メイン画面の ViewModel（Android 版の MainViewModel にあたる）。テーマと、アプリを開いたときのレビューのお願い（`ReviewPolicy`）。
@Observable
final class MainViewModel {
    private(set) var uiState: MainUiState

    private let observeThemeMode: ObserveThemeModeUseCase
    private let recordAppLaunch: RecordAppLaunchUseCase
    private let getReviewPrompt: GetReviewPromptUseCase
    private let answerFavorite: AnswerFavoriteUseCase
    private let markReviewAsked: MarkReviewAskedUseCase
    @ObservationIgnored private let eventChannel = EventChannel<MainEvent>()

    init(
        getThemeMode: GetThemeModeUseCase,
        observeThemeMode: ObserveThemeModeUseCase,
        recordAppLaunch: RecordAppLaunchUseCase,
        getReviewPrompt: GetReviewPromptUseCase,
        answerFavorite: AnswerFavoriteUseCase,
        markReviewAsked: MarkReviewAskedUseCase
    ) {
        self.observeThemeMode = observeThemeMode
        self.recordAppLaunch = recordAppLaunch
        self.getReviewPrompt = getReviewPrompt
        self.answerFavorite = answerFavorite
        self.markReviewAsked = markReviewAsked
        // 最初の画面から保存しているテーマで出す（ちらつかないように、すぐに読む）
        uiState = MainUiState(themeMode: getThemeMode())
    }

    func events() -> AsyncStream<MainEvent> { eventChannel.stream() }

    /// テーマ設定を監視する（画面が出ている間。View の `.task` から呼ぶ）。
    func observe() async {
        for await mode in observeThemeMode() {
            uiState.themeMode = mode
        }
    }

    /// アプリを開いたとき（新しく起動した・バックグラウンドから戻った。1回開くごとに1回だけ呼ぶ）。
    /// 開いた回数を数え、お願いがあれば出す。
    func onAppOpened() {
        recordAppLaunch()
        switch getReviewPrompt() {
        case .askFavorite:
            eventChannel.send(.askFavorite)
        case .askReview:
            markReviewAsked() // お願いは1回だけ（iOS がダイアログを出さなかったときも、もう聞かない）
            eventChannel.send(.requestReview)
        case .none:
            break
        }
    }

    /// 「気に入っていただけましたか？」の答え。
    func onFavoriteAnswered(liked: Bool) {
        answerFavorite(liked: liked)
        eventChannel.send(liked ? .thankForLiking : .thankForFeedback)
    }
}
