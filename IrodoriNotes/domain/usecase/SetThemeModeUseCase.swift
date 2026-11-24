import Foundation

/// テーマを変える（保存すると MainViewModel が監視していて、すぐ全画面に反映される）。
final class SetThemeModeUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(_ mode: ThemeMode) {
        settingsRepository.setThemeMode(mode)
    }
}
