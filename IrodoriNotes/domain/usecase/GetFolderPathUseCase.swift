import Foundation

/// フォルダタブ直下から指定したフォルダまでの階層（ナビゲーションバーの「趣味 › 読書」や階層の深さに使う）。
final class GetFolderPathUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction(folderId: Int64) async throws -> [FolderPathEntry] {
        try await folderRepository.getPath(id: folderId)
    }
}
