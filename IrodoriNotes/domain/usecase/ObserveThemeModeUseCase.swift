import Foundation

/// テーマ設定の監視（設定が変わるたびに流れる）。
final class ObserveThemeModeUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction() -> AsyncStream<ThemeMode> {
        settingsRepository.observeThemeMode()
    }
}
