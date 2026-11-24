import Foundation

/// フォルダのロックを付け外しする（外すときの認証は画面側で済ませてから呼ぶ）。中のフォルダ・メモも全階層まとめて守られる。
final class SetFolderLockedUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction(folderId: Int64, locked: Bool) async throws {
        try await folderRepository.setLocked(id: folderId, locked: locked)
    }
}
