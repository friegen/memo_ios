import Foundation

/// フォルダ削除の確認用に、一緒にゴミ箱へ移る中身（全階層のフォルダ・メモ）の件数を数える。
final class CountFolderContentsUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction(folderId: Int64) async throws -> FolderContents {
        try await folderRepository.countContents(id: folderId)
    }
}
