import Foundation

/// メモタブの並び順を保存する。
final class SetMemoTabSortUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(_ sort: MemoSort) {
        settingsRepository.setMemoTabSort(sort)
    }
}
