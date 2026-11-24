import Foundation

/// ゴミ箱のフォルダを完全削除するときに一緒に消える中身（全階層）の数。確認ダイアログに出す。
final class CountTrashedFolderContentsUseCase {
    private let trashRepository: TrashRepository

    init(trashRepository: TrashRepository) {
        self.trashRepository = trashRepository
    }

    func callAsFunction(folderId: Int64) async throws -> FolderContents {
        try await trashRepository.countContentsOfTrashedFolder(id: folderId)
    }
}
