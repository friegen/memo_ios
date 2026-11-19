import Foundation
import Testing
@testable import IrodoriNotes

/// 起動時のゴミ箱の期限切れ削除。
struct PurgeExpiredTrashUseCaseTests {

    @Test func deletesOnlyItemsOlderThan30Days() async throws {
        let day: Int64 = 24 * 60 * 60 * 1000
        let (container, _, clock) = try makeTestContainer(now: 100 * day)
        let memos = container.memoRepository
        let old = try await memos.createMemo(folderId: nil, html: "old", plainText: "old", now: 0)
        let recent = try await memos.createMemo(folderId: nil, html: "new", plainText: "new", now: 0)
        try await memos.moveToTrash(id: old, now: clock.nowValue - 31 * day)
        try await memos.moveToTrash(id: recent, now: clock.nowValue - 29 * day)

        try await container.makePurgeExpiredTrashUseCase()()

        #expect(try await container.database.memoRecord(old) == nil)
        #expect(try await container.database.memoRecord(recent) != nil)
    }
}
