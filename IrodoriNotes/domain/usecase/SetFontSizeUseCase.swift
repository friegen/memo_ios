import Foundation

/// メモ編集画面の文字の大きさを変える。
final class SetFontSizeUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(_ level: FontSizeLevel) {
        settingsRepository.setFontSize(level)
    }
}
