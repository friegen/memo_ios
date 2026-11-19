import Foundation

/// ゴミ箱のメモを元に戻す。削除直後の「元に戻す」と、ゴミ箱画面からの復元の両方で使う。
/// 元のフォルダもゴミ箱にある場合はフォルダごと戻るので、ゴミ箱画面では事前に確認すること。
final class RestoreMemoUseCase {
    private let trashRepository: TrashRepository
    private let clock: AppClock

    init(trashRepository: TrashRepository, clock: AppClock) {
        self.trashRepository = trashRepository
        self.clock = clock
    }

    func callAsFunction(memoId: Int64) async throws {
        try await trashRepository.restoreMemo(id: memoId, now: clock.now())
    }
}
