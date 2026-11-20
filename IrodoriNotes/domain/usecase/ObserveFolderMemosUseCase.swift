import Foundation

/// フォルダの中のメモを、フォルダ内のメモの並び順（全フォルダ共通）で並べて監視する。
final class ObserveFolderMemosUseCase {
    private let memoRepository: MemoRepository
    private let settingsRepository: SettingsRepository

    init(memoRepository: MemoRepository, settingsRepository: SettingsRepository) {
        self.memoRepository = memoRepository
        self.settingsRepository = settingsRepository
    }

    func callAsFunction(folderId: Int64) -> AsyncThrowingStream<SortedMemos, any Error> {
        let pairs = combineLatest(memoRepository.observeFolderMemos(folderId: folderId), settingsRepository.observeFolderMemoSort())
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
