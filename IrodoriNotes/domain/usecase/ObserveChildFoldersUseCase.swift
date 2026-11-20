import Foundation

/// フォルダの中のフォルダを、フォルダ一覧の並び順（フォルダタブと同じ）で並べて監視する。
final class ObserveChildFoldersUseCase {
    private let folderRepository: FolderRepository
    private let settingsRepository: SettingsRepository

    init(folderRepository: FolderRepository, settingsRepository: SettingsRepository) {
        self.folderRepository = folderRepository
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(parentId: Int64) -> AsyncThrowingStream<SortedFolders, any Error> {
        let pairs = combineLatest(folderRepository.observeChildFolders(parentId: parentId), settingsRepository.observeFolderListSort())
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
