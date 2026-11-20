import Foundation

/// フォルダの名前・色を変える（更新日は変えない）。名前の前後の空白は取り除く。
final class UpdateFolderUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction(folderId: Int64, name: String, color: FolderColor) async throws {
        let trimmed = FolderName.normalize(name)
        guard !trimmed.isEmpty else { throw FolderError.emptyName }
        try await folderRepository.updateFolder(id: folderId, name: trimmed, color: color)
    }
}
