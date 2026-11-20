import Foundation

/// 有効なフォルダすべてを木の順に並べた一覧（メモの移動先を選ぶのに使う）。
final class GetFolderTreeUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction() async throws -> [FolderTreeEntry] {
        try await folderRepository.getFolderTree()
    }
}
