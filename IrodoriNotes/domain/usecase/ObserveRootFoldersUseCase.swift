import Foundation

/// フォルダタブ直下のフォルダを、フォルダ一覧の並び順で並べて監視する。
final class ObserveRootFoldersUseCase {
    private let folderRepository: FolderRepository
    private let settingsRepository: SettingsRepository

    init(folderRepository: FolderRepository, settingsRepository: SettingsRepository) {
        self.folderRepository = folderRepository
        self.settingsRepository = settingsRepository
    }

    func callAsFunction() -> AsyncThrowingStream<SortedFolders, any Error> {
        let pairs = combineLatest(folderRepository.observeRootFolders(), settingsRepository.observeFolderListSort())
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await (folders, sort) in pairs {
                        continuation.yield(SortedFolders(sort: sort, folders: sort.sort(folders)))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
