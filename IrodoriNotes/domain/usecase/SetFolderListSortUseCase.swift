import Foundation

/// フォルダ一覧（フォルダタブ・フォルダの中のフォルダ）の並び順を保存する。
final class SetFolderListSortUseCase {
    private let settingsRepository: SettingsRepository

    init(settingsRepository: SettingsRepository) {
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(_ sort: FolderSort) {
        settingsRepository.setFolderListSort(sort)
    }
}
