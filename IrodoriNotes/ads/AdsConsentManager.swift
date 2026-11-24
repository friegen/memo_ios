import AppTrackingTransparency
import Foundation
import GoogleMobileAds
import Observation
import UserMessagingPlatform

/// 広告の同意の確認（Google の User Messaging Platform。Android 版の AdsConsentManager にあたる）と、
/// iOS のトラッキングの許可（ATT）。
///
/// - EEA・英国・スイスなど同意が必要な地域の利用者には、最初に同意の画面を出す
/// - AdMob で「IDFA の説明メッセージ」を作っておくと、UMP がその説明 → iOS の許可ダイアログ（ATT）の順に出す
/// - 同意の内容は設定画面の「広告のプライバシー設定」から変えられる（その地域の利用者だけ表示）
@Observable
final class AdsConsentManager {
    /// 設定画面に「広告のプライバシー設定」を出す必要があるか（同意の確認が済んだら決まる）。
    private(set) var isPrivacyOptionsRequired = false

    private let availability: AdsAvailability

    init(availability: AdsAvailability) {
        self.availability = availability
    }

    /// 広告を読み込んでよいか（同意の確認が済んでいる。同意しなかった場合も、パーソナライズしない広告なら出せる）。
    var canRequestAds: Bool {
        availability.isEnabled && ConsentInformation.shared.canRequestAds
    }

    /// 同意の状態を確かめ、必要なら同意の画面を出す（アプリを起動するたびに呼ぶ。Google の推奨）。
    /// - Parameter onFormWillShow: 同意の画面を出す直前（起動画面と同じ見た目の覆いを外すため）
    /// - Returns: この起動で同意の画面を出したか
    func gatherConsent(onFormWillShow: () -> Void) async -> Bool {
        guard availability.isEnabled else { return false }
        let parameters = RequestParameters()
        #if DEBUG
        parameters.debugSettings = Self.debugSettings()
        #endif
        do {
            try await ConsentInformation.shared.requestConsentInfoUpdate(with: parameters)
        } catch {
            // 確かめられなかった（オフラインなど）。前回までの同意の状態のまま進める
            AppLog.error("広告の同意の状態を確かめられなかった: \(error)")
            updatePrivacyOptions()
            return false
        }
        let formWillShow = ConsentInformation.shared.consentStatus == .required
        if formWillShow { onFormWillShow() }
        do {
            try await ConsentForm.loadAndPresentIfRequired(from: TopViewController.current())
        } catch {
            AppLog.error("広告の同意の画面を出せなかった: \(error)")
        }
        updatePrivacyOptions()
        return formWillShow
    }

    /// トラッキングの許可（ATT）をまだ聞いていなければ、iOS の許可ダイアログを出す。
    /// ふつうは UMP が「IDFA の説明メッセージ」の後に出すので、ここでは聞き終わっている。
    /// AdMob で説明メッセージを作っていないときなどのための予備。
    /// - Returns: この起動で許可ダイアログを出したか
    func requestTrackingIfNeeded(onWillShow: () -> Void) async -> Bool {
        guard availability.isEnabled, ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return false }
        onWillShow()
        _ = await ATTrackingManager.requestTrackingAuthorization()
        return true
    }

    /// 設定画面から、同意の内容を変える画面を出す。
    func showPrivacyOptionsForm() async {
        guard availability.isEnabled else { return }
        do {
            try await ConsentForm.presentPrivacyOptionsForm(from: TopViewController.current())
        } catch {
            AppLog.error("広告のプライバシー設定を出せなかった: \(error)")
        }
        updatePrivacyOptions()
    }

    private func updatePrivacyOptions() {
        isPrivacyOptionsRequired = availability.isEnabled
            && ConsentInformation.shared.privacyOptionsRequirementStatus == .required
    }

    #if DEBUG
    /// 開発中の確かめ方（Debug だけ）: 起動の引数で、同意が必要な地域にいることにする。
    /// - `-ump-debug-geography EEA`: EEA（ヨーロッパ）にいることにして、同意の画面を出す
    /// - `-ump-reset`: 同意の状態を消して、初めて起動したときと同じにする
    private static func debugSettings() -> DebugSettings? {
        let arguments = ProcessInfo.processInfo.arguments
        if arguments.contains("-ump-reset") { ConsentInformation.shared.reset() }
        guard let index = arguments.firstIndex(of: "-ump-debug-geography"), index + 1 < arguments.count else { return nil }
        let settings = DebugSettings()
        settings.geography = arguments[index + 1] == "EEA" ? .EEA : .other
        return settings
    }
    #endif
}

/// 広告の SDK の初期化。同意の確認が済んで広告を読み込めるようになってから、アプリで1回だけ行う（Android 版の MobileAdsInitializer）。
final class MobileAdsInitializer {
    private let consent: AdsConsentManager
    private var started = false

    init(consent: AdsConsentManager) {
        self.consent = consent
    }

    /// - Returns: 広告を読み込んでよい状態か
    func initializeIfAllowed() -> Bool {
        guard consent.canRequestAds else { return false }
        if !started {
            started = true
            MobileAds.shared.start(completionHandler: nil)
        }
        return true
    }
}
