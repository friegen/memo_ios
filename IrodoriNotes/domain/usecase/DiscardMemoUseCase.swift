import Foundation

/// メモをゴミ箱を通さずに完全に削除する。
/// 編集画面で新しく作ったメモ（自動保存で一度保存されたもの）を空にして閉じたときに使う。
/// 開いたときには存在しなかったメモなので、「何も書かずに閉じた」のと同じ扱いにする。
final class DiscardMemoUseCase {
    private let trashRepository: TrashRepository

    init(trashRepository: TrashRepository) {
        self.trashRepository = trashRepository
    }

    func callAsFunction(memoId: Int64) async throws {
        try await trashRepository.deleteMemoPermanently(id: memoId)
    }
}
