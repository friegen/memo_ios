import Foundation

/// 今のテーマ設定（起動直後の最初の画面に、ちらつかずにテーマを反映するため、すぐに読む）。
final class GetThemeModeUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction() -> ThemeMode {
        settingsRepository.themeMode
    }
}
