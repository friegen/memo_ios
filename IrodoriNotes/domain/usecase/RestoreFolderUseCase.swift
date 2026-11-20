import Foundation

/// ゴミ箱のフォルダを、一緒に削除された中身ごと元に戻す。削除直後の「元に戻す」と、ゴミ箱画面からの復元で使う。
/// 上の階層もゴミ箱にある場合はそれらも戻るので、ゴミ箱画面では事前に確認すること。
final class RestoreFolderUseCase {
    private let trashRepository: TrashRepository
    private let clock: AppClock

    init(trashRepository: TrashRepository, clock: AppClock) {
        self.trashRepository = trashRepository
        self.clock = clock
    }

    func callAsFunction(folderId: Int64) async throws {
        try await trashRepository.restoreFolder(id: folderId, now: clock.now())
    }
}
