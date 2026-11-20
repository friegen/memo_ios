import Foundation

/// 編集中のメモを保存する。
///
/// - 本文が空白だけ → 保存しない（新規なら作らない。既存なら前回保存した内容のまま残す）
///   既存メモを空にして閉じるときは、編集画面で確認ダイアログを出し、「削除する」を選んだときだけゴミ箱へ移す（勝手に消さない）
/// - 内容が前回と同じ → 何もしない（更新日を進めない）
final class SaveMemoUseCase {
    enum Result: Equatable {
        case created(memoId: Int64)
        case updated
        case unchanged
        case skippedEmpty
    }

    private let memoRepository: MemoRepository
    private let clock: AppClock

    init(memoRepository: MemoRepository, clock: AppClock) {
        self.memoRepository = memoRepository
        self.clock = clock
    }

    func callAsFunction(memoId: Int64?, folderId: Int64?, html: String, plainText: String) async throws -> Result {
        if plainText.isBlank { return .skippedEmpty }

        let now = clock.now()
        guard let memoId else {
            return .created(memoId: try await memoRepository.createMemo(folderId: folderId, html: html, plainText: plainText, now: now))
        }
        return try await memoRepository.updateMemo(id: memoId, html: html, plainText: plainText, now: now) ? .updated : .unchanged
    }
}
