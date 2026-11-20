import Foundation
import Testing
@testable import IrodoriNotes

/// フォルダの作成・変更の決まり（Android 版の CreateFolderUseCaseTest と同じ内容）。
struct CreateFolderUseCaseTests {
    let container: AppContainer

    init() throws {
        container = try makeTestContainer(now: 500).container
    }

    @Test func trimsNameAndPassesParentAndTime() async throws {
        let parent = try await container.makeCreateFolderUseCase()(parentId: nil, name: "親", color: .blue)
        let id = try await container.makeCreateFolderUseCase()(parentId: parent, name: "  趣味 \n", color: .green)

        let folder = try #require(try await container.folderRepository.observeFolder(id: id).firstValue())
        #expect(folder.name == "趣味")
        #expect(folder.parentId == parent)
        #expect(folder.color == .green)
        #expect(folder.createdAt == 500)
    }

    @Test func blankNameIsRejected() async throws {
        await #expect(throws: FolderError.emptyName) {
            _ = try await container.makeCreateFolderUseCase()(parentId: nil, name: "  ", color: .default)
        }
        let id = try await container.makeCreateFolderUseCase()(parentId: nil, name: "a", color: .default)
        await #expect(throws: FolderError.emptyName) {
            try await container.makeUpdateFolderUseCase()(folderId: id, name: "\n", color: .red)
        }
    }

    @Test func longNameIsCut() async throws {
        let id = try await container.makeCreateFolderUseCase()(
            parentId: nil, name: String(repeating: "あ", count: 60), color: .default)
        let folder = try #require(try await container.folderRepository.observeFolder(id: id).firstValue())
        #expect(folder.name.count == FolderPolicy.maxNameLength)
    }
}
