import Foundation
import GRDB

/// 有効な（ゴミ箱に入っていない）メモの取得・作成・更新・移動・ゴミ箱への移動。ゴミ箱の中の操作は `TrashRepository`。
///
/// フォルダ内のメモを追加・編集・削除・移動したときは、フォルダとその上の階層の更新日も同じトランザクションで進める。
final class MemoRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    /// メモタブのメモ（本文なし・並び替えは呼び出し側）。
    func observeMemoTabMemos() -> AsyncThrowingStream<[MemoSummary], any Error> {
        database.observe { db in try MemoDao.memoTabMemos(db).map { $0.toModel() } }
    }

    /// フォルダ内のメモ（本文なし・並び替えは呼び出し側）。
    func observeFolderMemos(folderId: Int64) -> AsyncThrowingStream<[MemoSummary], any Error> {
        database.observe { db in try MemoDao.folderMemos(db, folderId: folderId).map { $0.toModel() } }
    }

    /// 有効なメモを1件取得。ゴミ箱に入っている・存在しない場合は nil。ロックしている上の階層のフォルダも調べる。
    func getMemo(id: Int64) async throws -> Memo? {
        try await database.writer.read { db in
            guard let record = try MemoDao.findById(db, id: id), record.deletedAt == nil else { return nil }
            var lockedFolderIds: [Int64] = []
            if let folderId = record.folderId {
                lockedFolderIds = FolderTree(try FolderDao.getAll(db)).chainOf(folderId)
                    .filter(\.isLocked).map(\.savedId)
            }
            return record.toModel(lockedFolderIds: lockedFolderIds)
        }
    }

    /// ロックの付け外し（更新日は変えない）。
    func setLocked(id: Int64, locked: Bool) async throws {
        try await database.writer.write { db in try MemoDao.setLocked(db, id: id, locked: locked) }
    }

    /// ピン留めの付け外し。中身は変わらないので、更新日（メモ・フォルダとも）は進めない。
    func setPinned(id: Int64, pinned: Bool) async throws {
        try await database.writer.write { db in try MemoDao.setPinned(db, id: id, pinned: pinned) }
    }

    /// メモを作成する。一覧用の1行目と文字数はここで作る。
    /// - Parameter folderId: nil ならメモタブのメモ
    /// - Returns: 作成したメモの id
    func createMemo(folderId: Int64?, html: String, plainText: String, now: Int64) async throws -> Int64 {
        try await database.writer.write { db in
            let id = try MemoDao.insert(db, MemoRecord(
                folderId: folderId,
                html: html,
                plainText: plainText,
                firstLine: CharCounter.firstLine(plainText, maxChars: MemoPolicy.firstLineMaxChars),
                charCount: CharCounter.countChars(plainText),
                createdAt: now,
                updatedAt: now))
            if let folderId {
                try FolderDao.touchWithAncestors(db, folderIds: [folderId], now: now)
            }
            return id
        }
    }

    /// メモの本文を更新する。内容が変わっていなければ何もしない（自動保存で更新日が進まないように）。
    /// - Returns: 更新したら true
    @discardableResult
    func updateMemo(id: Int64, html: String, plainText: String, now: Int64) async throws -> Bool {
        try await database.writer.write { db in
            guard let current = try MemoDao.findById(db, id: id) else { return false }
            if current.html == html && current.plainText == plainText { return false }

            try MemoDao.updateContent(
                db, id: id, html: html, plainText: plainText,
                firstLine: CharCounter.firstLine(plainText, maxChars: MemoPolicy.firstLineMaxChars),
                charCount: CharCounter.countChars(plainText),
                updatedAt: now)
            if let folderId = current.folderId {
                try FolderDao.touchWithAncestors(db, folderIds: [folderId], now: now)
            }
            return true
        }
    }

    /// 本文と更新日を、指定した内容（編集画面を開いたときの内容）に戻す。
    /// 編集画面の「元に戻して閉じる」用。途中で自動保存した内容を捨て、更新日も開いたときの値に戻す。
    func revertMemo(id: Int64, html: String, plainText: String, updatedAt: Int64) async throws {
        try await database.writer.write { db in
            try MemoDao.updateContent(
                db, id: id, html: html, plainText: plainText,
                firstLine: CharCounter.firstLine(plainText, maxChars: MemoPolicy.firstLineMaxChars),
                charCount: CharCounter.countChars(plainText),
                updatedAt: updatedAt)
        }
    }

    /// フォルダ内のメモを別のフォルダ（どの階層でもよい）へ移動する（移動元・移動先とその上の階層の更新日を進める）。
    /// メモタブ ⇔ フォルダ間の移動は仕様上しないので、呼び出し側でフォルダ内のメモだけを渡すこと。
    func moveToFolder(memoIds: [Int64], targetFolderId: Int64, now: Int64) async throws {
        guard !memoIds.isEmpty else { return }
        try await database.writer.write { db in
            var folderIds = Set<Int64>()
            for id in memoIds {
                if let folderId = try MemoDao.findSummaryById(db, id: id)?.folderId { folderIds.insert(folderId) }
            }
            try MemoDao.moveToFolder(db, ids: memoIds, folderId: targetFolderId)
            folderIds.insert(targetFolderId)
            try FolderDao.touchWithAncestors(db, folderIds: folderIds, now: now)
        }
    }

    /// メモを単体でゴミ箱へ。元に戻すときは `TrashRepository.restoreMemo`。
    func moveToTrash(id: Int64, now: Int64) async throws {
        try await database.writer.write { db in
            guard let memo = try MemoDao.findSummaryById(db, id: id) else { return }
            try MemoDao.moveToTrash(db, id: id, deletedAt: now)
            if let folderId = memo.folderId {
                try FolderDao.touchWithAncestors(db, folderIds: [folderId], now: now)
            }
        }
    }
}
