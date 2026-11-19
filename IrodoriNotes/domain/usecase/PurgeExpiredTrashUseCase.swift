import Foundation

/// ゴミ箱に入れてから30日たったものを完全削除する（アプリの起動時に呼ぶ）。
final class PurgeExpiredTrashUseCase {
    private let trashRepository: TrashRepository
    private let clock: AppClock

    init(trashRepository: TrashRepository, clock: AppClock) {
        self.trashRepository = trashRepository
        self.clock = clock
    }

    func callAsFunction() async throws {
        try await trashRepository.purgeExpired(now: clock.now())
    }
}
