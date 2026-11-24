import Foundation

/// ゴミ箱のフォルダを、中身（ゴミ箱内のものすべて）ごと完全に削除する（画面で確認してから呼ぶ）。
final class DeleteFolderPermanentlyUseCase {
    private let trashRepository: TrashRepository

    init(trashRepository: TrashRepository) {
        self.trashRepository = trashRepository
    }

    func callAsFunction(folderId: Int64) async throws {
        try await trashRepository.deleteFolderPermanently(id: folderId)
    }
}
