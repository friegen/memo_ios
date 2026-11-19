import Foundation

/// メモのピン留めの付け外し（更新日は変えない）。
final class SetMemoPinnedUseCase {
    private let memoRepository: MemoRepository

    init(memoRepository: MemoRepository) {
        self.memoRepository = memoRepository
    }

    func callAsFunction(memoId: Int64, pinned: Bool) async throws {
        try await memoRepository.setPinned(id: memoId, pinned: pinned)
    }
}
