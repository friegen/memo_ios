import Foundation

/// フォルダのピン留めの付け外し（更新日は変えない）。
final class SetFolderPinnedUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction(folderId: Int64, pinned: Bool) async throws {
        try await folderRepository.setPinned(id: folderId, pinned: pinned)
    }
}
