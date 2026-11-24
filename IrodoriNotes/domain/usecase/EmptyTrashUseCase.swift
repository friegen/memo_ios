import Foundation

/// ゴミ箱を空にする（画面で確認してから呼ぶ）。
final class EmptyTrashUseCase {
    private let trashRepository: TrashRepository

    init(trashRepository: TrashRepository) {
        self.trashRepository = trashRepository
    }

    func callAsFunction() async throws {
        try await trashRepository.emptyTrash()
    }
}
