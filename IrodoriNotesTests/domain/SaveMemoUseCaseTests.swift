import Foundation
import Testing
@testable import IrodoriNotes

/// 保存の決まり（Android 版の SaveMemoUseCaseTest と同じ内容）。
struct SaveMemoUseCaseTests {
    let container: AppContainer
    let clock: FixedClock

    init() throws {
        (container, _, clock) = try makeTestContainer(now: 100)
    }

    @Test func newMemo_createdThenUpdatedThenUnchanged() async throws {
        let saveMemo = container.makeSaveMemoUseCase()
        guard case .created(let id) = try await saveMemo(memoId: nil, folderId: nil, html: "a", plainText: "a") else {
            Issue.record("作られなかった")
            return
        }

        clock.nowValue = 200
        #expect(try await saveMemo(memoId: id, folderId: nil, html: "ab", plainText: "ab") == .updated)
        #expect(try await saveMemo(memoId: id, folderId: nil, html: "ab", plainText: "ab") == .unchanged)

        let memo = try #require(try await container.memoRepository.getMemo(id: id))
        #expect(memo.plainText == "ab")
        #expect(memo.updatedAt == 200)
    }

    @Test func newMemo_blank_isNotSaved() async throws {
        #expect(try await container.makeSaveMemoUseCase()(memoId: nil, folderId: nil, html: "", plainText: "  \n ") == .skippedEmpty)
        #expect(try await container.memoRepository.observeMemoTabMemos().firstValue().isEmpty)
    }

    /// 既存メモを空にしても勝手に消さない（削除は編集画面の確認ダイアログで「削除する」を選んだときだけ）。
    @Test func existingMemo_blank_isNotSavedAndKept() async throws {
        let id = try await container.memoRepository.createMemo(folderId: nil, html: "a", plainText: "a", now: 1)

        #expect(try await container.makeSaveMemoUseCase()(memoId: id, folderId: nil, html: "", plainText: " \n") == .skippedEmpty)

        #expect(try await container.memoRepository.getMemo(id: id)?.plainText == "a")
    }
}
