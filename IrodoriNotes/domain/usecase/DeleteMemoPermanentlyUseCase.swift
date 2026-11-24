import Foundation

/// ゴミ箱のメモを完全に削除する（元に戻せないので、画面で確認してから呼ぶ）。
final class DeleteMemoPermanentlyUseCase {
    private let trashRepository: TrashRepository

    init(trashRepository: TrashRepository) {
        self.trashRepository = trashRepository
    }

    func callAsFunction(memoId: Int64) async throws {
        try await trashRepository.deleteMemoPermanently(id: memoId)
    }
}
