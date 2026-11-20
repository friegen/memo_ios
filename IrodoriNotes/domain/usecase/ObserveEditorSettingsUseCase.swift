import Foundation

/// メモ編集画面の文字の大きさ・行間の監視。
final class ObserveEditorSettingsUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction() -> AsyncStream<EditorSettings> {
        settingsRepository.observeEditorSettings()
    }
}
