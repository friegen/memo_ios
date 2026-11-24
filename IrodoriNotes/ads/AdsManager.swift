import Foundation
import Observation

/// 広告まわりをまとめたもの（アプリで1つ。`AppContainer.ads`）。
///
/// - 新しく起動したとき（`handleColdLaunch`）: 起動画面と同じ見た目の覆い（`isSplashVisible`）を出したまま、
///   同意の確認（UMP）→ トラッキングの許可（ATT）→ アプリ起動広告（間に合えば）。待つのは最大 `AdPolicy.appOpenColdStartWait`。
///   同意の画面・許可のダイアログを出したときは覆いを外し、その起動ではアプリ起動広告を出さない（docs/requirements.md「広告」）
/// - バックグラウンドから戻ったとき（`onForeground`）: アプリ起動広告
/// - バナー（メイン画面・編集画面）とリワード広告（フォルダの中にフォルダを作るとき）
@Observable
final class AdsManager {
    /// 起動画面と同じ見た目の覆いを出しているか（新しく起動したときだけ。iOS の起動画面は止まった絵で、待たせられないため）
    private(set) var isSplashVisible: Bool
    /// 同意の確認が済んで、バナーを出してよくなったか
    private(set) var canShowBanners = false
    /// メモの編集画面が出ているか（出ている間はメイン画面のバナーを隠す。編集画面は自分のバナーを出す）
    private(set) var editorScreenCount = 0

    let availability: AdsAvailability
    let consent: AdsConsentManager
    @ObservationIgnored let appOpen: AppOpenAdManager
    @ObservationIgnored let rewarded: RewardedAdLoader
    @ObservationIgnored private let initializer: MobileAdsInitializer
    @ObservationIgnored private var hasHandledColdLaunch = false

    init(
        availability: AdsAvailability,
        shouldShowAppOpenAd: ShouldShowAppOpenAdUseCase,
        recordAppOpenAdShown: RecordAppOpenAdShownUseCase,
        clock: AppClock
    ) {
        self.availability = availability
        isSplashVisible = availability.isEnabled
        consent = AdsConsentManager(availability: availability)
        initializer = MobileAdsInitializer(consent: consent)
        appOpen = AppOpenAdManager(
            initializer: initializer, shouldShowAppOpenAd: shouldShowAppOpenAd, recordAppOpenAdShown: recordAppOpenAdShown,
            clock: clock)
        rewarded = RewardedAdLoader(initializer: initializer, appOpenAdManager: appOpen)
    }

    /// 新しく起動したとき（MainView から1回だけ）。
    func handleColdLaunch() async {
        guard !hasHandledColdLaunch else { return }
        hasHandledColdLaunch = true
        guard availability.isEnabled else {
            isSplashVisible = false
            return
        }
        let deadline = ContinuousClock.now + AdPolicy.appOpenColdStartWait
        // 待つのはここまで（広告が間に合わなくても覆いを外す）
        Task { [weak self] in
            try? await Task.sleep(until: deadline, clock: .continuous)
            self?.isSplashVisible = false
        }
        let formShown = await consent.gatherConsent(onFormWillShow: { isSplashVisible = false })
        let trackingAsked = await consent.requestTrackingIfNeeded(onWillShow: { isSplashVisible = false })
        canShowBanners = initializer.initializeIfAllowed()
        if formShown || trackingAsked || ContinuousClock.now >= deadline {
            isSplashVisible = false
            appOpen.loadIfNeeded() // 次に戻ってきたとき用
            return
        }
        await appOpen.handleColdStart(deadline: deadline)
        isSplashVisible = false
    }

    /// バックグラウンドから戻ったとき。
    func onForeground() async {
        guard availability.isEnabled, !hasHandledColdLaunch || !isSplashVisible else { return }
        await appOpen.onForeground()
    }

    func editorDidAppear() { editorScreenCount += 1 }

    func editorDidDisappear() { editorScreenCount = max(0, editorScreenCount - 1) }

    /// 設定画面から、広告の同意の内容を変える画面を出す。
    func showPrivacyOptionsForm() async {
        await consent.showPrivacyOptionsForm()
        canShowBanners = initializer.initializeIfAllowed()
    }
}
