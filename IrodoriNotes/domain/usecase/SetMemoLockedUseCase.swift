import Foundation

/// メモのロックを付け外しする（外すときの認証は画面側で済ませてから呼ぶ）。
final class SetMemoLockedUseCase {
    private let memoRepository: MemoRepository

    init(memoRepository: MemoRepository) {
        self.memoRepository = memoRepository
    }

    func callAsFunction(memoId: Int64, locked: Bool) async throws {
        try await memoRepository.setLocked(id: memoId, locked: locked)
    }
}
