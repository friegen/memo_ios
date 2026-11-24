import Foundation

/// 広告の出し方を決めるための記録（UserDefaults。Android 版の AdStateRepository にあたる）。
/// - アプリを開いた回数・アプリ起動広告を前回出した時刻
/// - リワード広告を見て得た「フォルダの中にフォルダを作れる残りの数」
final class AdStateRepository {
    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    /// アプリを開いた回数を1増やし、増やした後の回数を返す。
    func incrementLaunchCount() -> Int {
        let count = launchCount + 1
        defaults.set(count, forKey: SettingsKeys.appLaunchCount)
        return count
    }

    var launchCount: Int { defaults.integer(forKey: SettingsKeys.appLaunchCount) }

    var appOpenAdLastShownAt: Int64? {
        (defaults.object(forKey: SettingsKeys.appOpenAdLastShownAt) as? NSNumber)?.int64Value
    }

    func setAppOpenAdLastShownAt(_ time: Int64) {
        defaults.set(NSNumber(value: time), forKey: SettingsKeys.appOpenAdLastShownAt)
    }

    var subfolderCredits: Int { defaults.integer(forKey: SettingsKeys.subfolderCredits) }

    func addSubfolderCredits(_ count: Int) {
        defaults.set(subfolderCredits + count, forKey: SettingsKeys.subfolderCredits)
    }

    /// 1つ使う。0 のときは 0 のまま（広告を出せず、広告なしで作った場合）。
    func consumeSubfolderCredit() {
        defaults.set(max(0, subfolderCredits - 1), forKey: SettingsKeys.subfolderCredits)
    }
}
