import Foundation

/// フォルダを作る。名前の前後の空白は取り除き、50文字までにする。
final class CreateFolderUseCase {
    private let folderRepository: FolderRepository
    private let clock: AppClock

    init(folderRepository: FolderRepository, clock: AppClock) {
        self.folderRepository = folderRepository
        self.clock = clock
    }

    /// - Parameter parentId: nil ならフォルダタブ直下
    /// - Returns: 作成したフォルダの id
    /// - Throws: `FolderError.emptyName`（名前が空）、`FolderError.depthLimitReached`（親が最大の階層）。どちらも画面側で防ぐこと
    func callAsFunction(parentId: Int64?, name: String, color: FolderColor) async throws -> Int64 {
        let trimmed = FolderName.normalize(name)
        guard !trimmed.isEmpty else { throw FolderError.emptyName }
        return try await folderRepository.createFolder(parentId: parentId, name: trimmed, color: color, now: clock.now())
    }
}

/// フォルダ名の決まり（前後の空白を除き、`FolderPolicy.maxNameLength` 文字まで）。
nonisolated enum FolderName {
    static func normalize(_ name: String) -> String {
        String(name.trimmingCharacters(in: .whitespacesAndNewlines).prefix(FolderPolicy.maxNameLength))
    }
}
