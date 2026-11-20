import Foundation
import Testing
@testable import IrodoriNotes

/// フォルダタブ直下のフォルダを並び順で並べて監視する（Android 版の ObserveRootFoldersUseCaseTest にあたる）。
struct ObserveRootFoldersUseCaseTests {

    @Test func sortsBySavedSortAndExcludesSubfoldersAndTrash() async throws {
        let (container, _, _) = try makeTestContainer()
        let folders = container.folderRepository
        let b = try await folders.createFolder(parentId: nil, name: "B", color: .default, now: 1)
        let a = try await folders.createFolder(parentId: nil, name: "A", color: .default, now: 2)
        _ = try await folders.createFolder(parentId: b, name: "child", color: .default, now: 3) // 中のフォルダは出ない
        let trashed = try await folders.createFolder(parentId: nil, name: "T", color: .default, now: 4)
        try await folders.moveToTrash(id: trashed, now: 5)

        var iterator = container.makeObserveRootFoldersUseCase()().makeAsyncIterator()
        let first = try #require(try await iterator.next())
        #expect(first.folders.map(\.id) == [b, a]) // 既定は更新日の新しい順（B は中にフォルダを作ったので更新日が 3）

        container.makeSetFolderListSortUseCase()(FolderSort(key: .name, ascending: true))
        let second = try #require(try await iterator.next())
        #expect(second.sort == FolderSort(key: .name, ascending: true))
        #expect(second.folders.map(\.id) == [a, b])
    }
}
