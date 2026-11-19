import Foundation
import Testing
@testable import IrodoriNotes

/// メモタブのメモを並び順で並べて監視する。
struct ObserveMemoTabMemosUseCaseTests {

    @Test func sortsBySavedSortAndFollowsSortChanges() async throws {
        let (container, _, _) = try makeTestContainer()
        let memos = container.memoRepository
        let short = try await memos.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)
        let long = try await memos.createMemo(folderId: nil, html: "abc", plainText: "abc", now: 2)
        let inFolder = try await container.folderRepository.createFolder(parentId: nil, name: "F", color: .default, now: 1)
        _ = try await memos.createMemo(folderId: inFolder, html: "x", plainText: "x", now: 3) // フォルダのメモは出ない

        var iterator = container.makeObserveMemoTabMemosUseCase()().makeAsyncIterator()
        let first = try #require(try await iterator.next())
        #expect(first.sort == MemoSort())
        #expect(first.memos.map(\.id) == [long, short]) // 既定は更新日の新しい順

        container.makeSetMemoTabSortUseCase()(MemoSort(key: .charCount, ascending: true))
        let second = try #require(try await iterator.next())
        #expect(second.sort == MemoSort(key: .charCount, ascending: true))
        #expect(second.memos.map(\.id) == [short, long])
    }
}
