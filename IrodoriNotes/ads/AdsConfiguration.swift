import Foundation

/// この環境で広告（AdMob・UMP・ATT）を使うか（Android 版の AdsAvailability にあたる）。
/// 単体テスト・UI テストでは使わない（広告の SDK は通信や本物の画面が要り、テストの結果が安定しないため。
/// 広告まわりの決まりは AdPolicy と ViewModel の単体テストで確かめる）。
nonisolated struct AdsAvailability: Sendable {
    let isEnabled: Bool

    static let current: AdsAvailability = {
        let process = ProcessInfo.processInfo
        let isUnitTest = process.environment["XCTestConfigurationFilePath"] != nil
        // UI テストでも `-ui-test-enable-ads` を付けたときだけは使う（テスト用の広告の見た目を確かめるため。Debug だけ）
        let isUITest = process.arguments.contains("-ui-testing") && !process.arguments.contains("-ui-test-enable-ads")
        return AdsAvailability(isEnabled: !isUnitTest && !isUITest)
    }()
}

/// AdMob の広告ユニットの ID。ビルドの設定（project.xcproj の ADMOB_*）から Info.plist に入れたものを読む。
/// Debug はテスト用の ID、Release は本物の ID（本物の広告をタップするとアカウントが止まることがあるため、開発中は使わない）。
nonisolated enum AdUnitIDs {
    static var bannerMain: String { value("AdMobBannerMainID") }
    static var bannerEditor: String { value("AdMobBannerEditorID") }
    static var appOpen: String { value("AdMobAppOpenID") }
    static var rewardedFolder: String { value("AdMobRewardedFolderID") }

    private static func value(_ key: String) -> String {
        Bundle.main.object(forInfoDictionaryKey: key) as? String ?? ""
    }
}

/// AdMob のエラーを、アプリで扱う理由に変える（Android 版の adLoadFailureOf にあたる）。
nonisolated func adLoadFailure(of error: any Error) -> AdLoadFailure {
    let error = error as NSError
    guard error.domain == "com.google.admob" || error.domain == "com.google.ads" || error.domain.hasPrefix("com.google") else {
        return .other
    }
    switch error.code {
    case 1, 9: return .noFill // 在庫なし（メディエーションの在庫なしも）
    case 2: return .network
    case 11: return .internalError
    default: return .other
    }
}
