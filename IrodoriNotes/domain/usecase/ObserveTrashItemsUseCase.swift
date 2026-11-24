import Foundation

/// ゴミ箱の中身の監視（削除日時の新しい順。フォルダは削除の起点になったものだけを1項目にする）。
final class ObserveTrashItemsUseCase {
    private let trashRepository: TrashRepository

    init(trashRepository: TrashRepository) {
        self.trashRepository = trashRepository
    }

    func callAsFunction() -> AsyncThrowingStream<[TrashItem], any Error> {
        trashRepository.observeTrashItems()
    }
}
