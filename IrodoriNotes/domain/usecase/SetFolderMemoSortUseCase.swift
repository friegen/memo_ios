import Foundation

/// フォルダ内のメモの並び順（全フォルダ共通）を保存する。
final class SetFolderMemoSortUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(_ sort: MemoSort) {
        settingsRepository.setFolderMemoSort(sort)
    }
}
