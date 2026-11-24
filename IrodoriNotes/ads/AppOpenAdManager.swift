import GoogleMobileAds
import UIKit

/// アプリ起動広告（Android 版の AppOpenAdManager にあたる。docs/requirements.md「広告」）。
///
/// - 新しく起動したとき: `AdsManager` が起動画面と同じ見た目の覆いを出したまま `handleColdStart` を呼ぶ。
///   準備が `AdPolicy.appOpenColdStartWait` 以内に間に合えば出し、間に合わなければその回は出さない
/// - バックグラウンドから戻ったとき: 読み込み済みなら出す（`onForeground`）
/// - どちらも `ShouldShowAppOpenAdUseCase`（レビューのお願いの流れで広告を出してよい段階・前回から4時間以上）を満たすときだけ
/// - 共有シートから別のアプリに移って戻ったときは出さない（`beginExternalScreen` / `endExternalScreen`）
/// - 読み込んだ広告は4時間で使えなくなるので、古ければ読み込み直す
final class AppOpenAdManager: NSObject, FullScreenContentDelegate {
    /// 広告（アプリ起動広告・リワード広告）を全画面で出している間は true。重ねて出さないため
    var isFullScreenAdShowing = false

    private let initializer: MobileAdsInitializer
    private let shouldShowAppOpenAd: ShouldShowAppOpenAdUseCase
    private let recordAppOpenAdShown: RecordAppOpenAdShownUseCase
    private let clock: AppClock

    private var ad: AppOpenAd?
    private var loadedAt: Int64 = 0
    private var loadTask: Task<Void, Never>?
    private var dismissContinuation: CheckedContinuation<Void, Never>?
    private var skipNextForeground = false

    init(
        initializer: MobileAdsInitializer,
        shouldShowAppOpenAd: ShouldShowAppOpenAdUseCase,
        recordAppOpenAdShown: RecordAppOpenAdShownUseCase,
        clock: AppClock
    ) {
        self.initializer = initializer
        self.shouldShowAppOpenAd = shouldShowAppOpenAd
        self.recordAppOpenAdShown = recordAppOpenAdShown
        self.clock = clock
    }

    /// 共有シートなど、ほかのアプリに移ることがある画面を出す。その間にアプリから離れて戻っても広告を出さない。
    func beginExternalScreen() {
        skipNextForeground = true
    }

    /// その画面を閉じた。アプリの中で閉じたなら元に戻す（ほかのアプリに移ったままなら、戻ってきたときに1回だけ出さない）。
    func endExternalScreen() {
        if UIApplication.shared.applicationState == .active { skipNextForeground = false }
    }

    /// 新しく起動したとき。`deadline` までに準備できたら出し、閉じるまで待つ。
    func handleColdStart(deadline: ContinuousClock.Instant) async {
        guard initializer.initializeIfAllowed(), shouldShowAppOpenAd() else {
            loadIfNeeded()
            return
        }
        if !isAdFresh { await waitForLoad(until: deadline) }
        guard isAdFresh, ContinuousClock.now < deadline else { return }
        await show()
    }

    /// バックグラウンドから戻ったとき。
    func onForeground() async {
        if skipNextForeground {
            skipNextForeground = false
            return
        }
        guard !isFullScreenAdShowing, initializer.initializeIfAllowed() else { return }
        if shouldShowAppOpenAd() && isAdFresh {
            await show()
        } else {
            loadIfNeeded()
        }
    }

    private var isAdFresh: Bool {
        ad != nil && clock.now() - loadedAt < AdPolicy.appOpenAdExpiryMillis
    }

    /// 次に出せるよう、広告がない（または古い）ときだけ読み込んでおく。
    func loadIfNeeded() {
        if !isAdFresh && initializer.initializeIfAllowed() { _ = startLoading() }
    }

    private func startLoading() -> Task<Void, Never> {
        if let loadTask { return loadTask }
        let task = Task { [weak self] in
            do {
                let loaded = try await AppOpenAd.load(with: AdUnitIDs.appOpen, request: Request())
                guard let self else { return }
                ad = loaded
                loadedAt = clock.now()
            } catch {
                AppLog.error("アプリ起動広告を読み込めなかった: \(error)")
            }
            self?.loadTask = nil
        }
        loadTask = task
        return task
    }

    /// 読み込みが終わるか、`deadline` になるまで待つ（読み込みは止めない。間に合わなかった広告は次に使う）。
    private func waitForLoad(until deadline: ContinuousClock.Instant) async {
        let task = startLoading()
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await task.value }
            group.addTask { try? await Task.sleep(until: deadline, clock: .continuous) }
            await group.next()
            group.cancelAll()
        }
    }

    /// 出して、閉じるまで待つ。
    private func show() async {
        guard let ad, !isFullScreenAdShowing, let presenter = TopViewController.current() else { return }
        isFullScreenAdShowing = true
        ad.fullScreenContentDelegate = self
        await withCheckedContinuation { continuation in
            dismissContinuation = continuation
            ad.present(from: presenter)
        }
    }

    // MARK: FullScreenContentDelegate

    func adWillPresentFullScreenContent(_ ad: any FullScreenPresentingAd) {
        recordAppOpenAdShown()
    }

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        finishShowing()
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        AppLog.error("アプリ起動広告を出せなかった: \(error)")
        finishShowing()
    }

    private func finishShowing() {
        ad = nil // 1回出した広告は使い回さない
        isFullScreenAdShowing = false
        dismissContinuation?.resume()
        dismissContinuation = nil
        loadIfNeeded()
    }
}
