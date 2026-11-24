import Foundation

/// メモ編集画面の行間を変える。
final class SetLineSpacingUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(_ level: LineSpacingLevel) {
        settingsRepository.setLineSpacing(level)
    }
}
