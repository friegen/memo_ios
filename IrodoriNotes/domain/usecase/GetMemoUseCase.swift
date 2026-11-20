import Foundation

/// 編集画面用に、本文を含めてメモを1件読む。ゴミ箱に入っている・存在しない場合は nil。
final class GetMemoUseCase {
    private let memoRepository: MemoRepository

    init(memoRepository: MemoRepository) {
        self.memoRepository = memoRepository
    }

    func callAsFunction(memoId: Int64) async throws -> Memo? {
        try await memoRepository.getMemo(id: memoId)
    }
}
