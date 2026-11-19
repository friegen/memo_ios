import Foundation

/// メモを単体でゴミ箱へ移す（フォルダ内のメモならフォルダの更新日も進む）。
final class MoveMemoToTrashUseCase {
    private let memoRepository: MemoRepository
    private let clock: AppClock

    init(memoRepository: MemoRepository, clock: AppClock) {
        self.memoRepository = memoRepository
        self.clock = clock
    }

    func callAsFunction(memoId: Int64) async throws {
        try await memoRepository.moveToTrash(id: memoId, now: clock.now())
    }
}
