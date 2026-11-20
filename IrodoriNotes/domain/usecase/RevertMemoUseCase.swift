import Foundation

/// メモを、編集画面を開いたときの内容（本文・更新日）に戻す。空にしたメモを「元に戻して閉じる」ときに使う。
final class RevertMemoUseCase {
    private let memoRepository: MemoRepository

    init(memoRepository: MemoRepository) {
        self.memoRepository = memoRepository
    }

    func callAsFunction(original: Memo) async throws {
        try await memoRepository.revertMemo(
            id: original.id, html: original.html, plainText: original.plainText, updatedAt: original.updatedAt)
    }
}
