import Foundation

/// フォルダの中のメモを別のフォルダ（どの階層でもよい）へ移す。移動元・移動先とその上の階層の更新日が進む（メモの更新日は変わらない）。
final class MoveMemoToFolderUseCase {
    private let memoRepository: MemoRepository
    private let clock: AppClock

    init(memoRepository: MemoRepository, clock: AppClock) {
        self.memoRepository = memoRepository
        self.clock = clock
    }

    func callAsFunction(memoId: Int64, targetFolderId: Int64) async throws {
        try await memoRepository.moveToFolder(memoIds: [memoId], targetFolderId: targetFolderId, now: clock.now())
    }
}
