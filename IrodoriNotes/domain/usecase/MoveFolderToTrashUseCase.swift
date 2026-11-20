import Foundation

/// フォルダを中身（全階層）ごとゴミ箱へ移す。
final class MoveFolderToTrashUseCase {
    private let folderRepository: FolderRepository
    private let clock: AppClock

    init(folderRepository: FolderRepository, clock: AppClock) {
        self.folderRepository = folderRepository
        self.clock = clock
    }

    func callAsFunction(folderId: Int64) async throws {
        try await folderRepository.moveToTrash(id: folderId, now: clock.now())
    }
}
