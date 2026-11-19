import Foundation

/// メモタブのメモを、メモタブ用の並び順で並べて監視する。メモか並び順が変わるたびに流れる。
final class ObserveMemoTabMemosUseCase {
    private let memoRepository: MemoRepository
    private let settingsRepository: SettingsRepository

    init(memoRepository: MemoRepository, settingsRepository: SettingsRepository) {
        self.memoRepository = memoRepository
        self.settingsRepository = settingsRepository
    }

    func callAsFunction() -> AsyncThrowingStream<SortedMemos, any Error> {
        let pairs = combineLatest(memoRepository.observeMemoTabMemos(), settingsRepository.observeMemoTabSort())
        return AsyncThrowingStream { continuation in
            let task = Task {
                do {
                    for try await (memos, sort) in pairs {
                        continuation.yield(SortedMemos(sort: sort, memos: sort.sort(memos)))
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
