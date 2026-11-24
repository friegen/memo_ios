import GoogleMobileAds
import UIKit

/// リワード広告（フォルダの中にフォルダを作るとき）を読み込んで出す（Android 版の RewardedAdLoader にあたる）。
final class RewardedAdLoader: NSObject, FullScreenContentDelegate {
    private let initializer: MobileAdsInitializer
    private let appOpenAdManager: AppOpenAdManager

    /// 読み込みの結果（時間切れの間は nil）
    private var loaded: LoadOutcome?
    private var dismissContinuation: CheckedContinuation<Void, Never>?
    private var failedToPresent = false

    init(initializer: MobileAdsInitializer, appOpenAdManager: AppOpenAdManager) {
        self.initializer = initializer
        self.appOpenAdManager = appOpenAdManager
    }

    /// 読み込んで出し、結果を返す。
    /// - Parameter onLoaded: 読み込めて、広告を出す直前（「読み込んでいます」の表示を閉じるため）
    func loadAndShow(onLoaded: () -> Void) async -> RewardedAdResult {
        guard initializer.initializeIfAllowed() else { return .failed(.unavailable) }
        loaded = nil
        let loadTask = Task { [weak self] in
            do {
                let ad = try await RewardedAd.load(with: AdUnitIDs.rewardedFolder, request: Request())
                self?.loaded = .loaded(ad)
            } catch {
                AppLog.error("リワード広告を読み込めなかった: \(error)")
                self?.loaded = .failed(adLoadFailure(of: error))
            }
        }
        await withTaskGroup(of: Void.self) { group in
            group.addTask { await loadTask.value }
            group.addTask { try? await Task.sleep(for: AdPolicy.rewardedLoadTimeout) }
            await group.next()
            group.cancelAll()
        }
        switch loaded {
        case nil:
            return .failed(.other) // 時間切れ（通信が遅いだけのこともあるので広告ブロック扱いにしない）
        case .failed(let failure):
            return .failed(failure)
        case .loaded(let ad):
            loaded = nil
            onLoaded()
            return await show(ad)
        }
    }

    private func show(_ ad: RewardedAd) async -> RewardedAdResult {
        guard let presenter = TopViewController.current() else { return .failed(.other) }
        var earned = false
        failedToPresent = false
        appOpenAdManager.isFullScreenAdShowing = true
        ad.fullScreenContentDelegate = self
        await withCheckedContinuation { continuation in
            dismissContinuation = continuation
            ad.present(from: presenter) { earned = true }
        }
        appOpenAdManager.isFullScreenAdShowing = false
        if failedToPresent { return .failed(.other) }
        return earned ? .earned : .dismissed
    }

    private enum LoadOutcome {
        case loaded(RewardedAd)
        case failed(AdLoadFailure)
    }

    // MARK: FullScreenContentDelegate

    func adDidDismissFullScreenContent(_ ad: any FullScreenPresentingAd) {
        dismissContinuation?.resume()
        dismissContinuation = nil
    }

    func ad(_ ad: any FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: any Error) {
        AppLog.error("リワード広告を出せなかった: \(error)")
        failedToPresent = true
        dismissContinuation?.resume()
        dismissContinuation = nil
    }
}
