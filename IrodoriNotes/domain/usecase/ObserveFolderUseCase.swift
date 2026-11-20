import Foundation

/// フォルダ1件の監視（フォルダの中の画面のタイトル用）。ゴミ箱に入った・存在しない場合は nil が流れる。
final class ObserveFolderUseCase {
    private let folderRepository: FolderRepository

    init(folderRepository: FolderRepository) {
        self.folderRepository = folderRepository
    }

    func callAsFunction(folderId: Int64) -> AsyncThrowingStream<Folder?, any Error> {
        folderRepository.observeFolder(id: folderId)
    }
}
