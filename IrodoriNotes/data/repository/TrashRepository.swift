import Foundation
import GRDB

/// ゴミ箱の表示・復元・完全削除。
///
/// 決まり（Android 版 requirements.md「削除とゴミ箱」）:
/// - メモ・フォルダは必ず存在する（ゴミ箱に入っていない）フォルダに属する
/// - フォルダを復元すると、一緒に削除された中身（全階層）だけを戻す（先に単体で削除した中身はゴミ箱に残す）
/// - 上の階層がゴミ箱にあるメモ・フォルダを復元するときは、上の階層もまとめて復元する（画面側で事前に確認する）
/// - フォルダを完全削除すると、中身（ゴミ箱内のものすべて）も CASCADE で完全削除される
/// - 復元は「中身の追加」として、復元先のフォルダとその上の階層の更新日を進める
final class TrashRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    /// ゴミ箱の中身。削除日時の新しい順。フォルダは削除の起点になったものだけを1項目にする。
    func observeTrashItems() -> AsyncThrowingStream<[TrashItem], any Error> {
        database.observe { db in
            let memos = try MemoDao.trashedMemos(db)
            let folders = try FolderDao.getAll(db)
            let deletedWithCounts = try MemoDao.deletedWithFolderCounts(db)
            return Self.trashItems(memos: memos, folders: folders, deletedWithCounts: deletedWithCounts)
        }
    }

    private nonisolated static func trashItems(
        memos: [MemoSummaryRow], folders: [FolderRecord], deletedWithCounts: [FolderIdCountRow]
    ) -> [TrashItem] {
        let tree = FolderTree(folders)
        let memoCountByFolder = Dictionary(deletedWithCounts.map { ($0.folderId, $0.count) }, uniquingKeysWith: +)

        let memoItems: [TrashItem] = memos.compactMap { row in
            guard let deletedAt = row.deletedAt else { return nil }
            let chain = row.folderId.map { tree.chainOf($0) } ?? []
            return .memo(TrashedMemo(
                memo: row.toModel(),
                folderName: chain.first?.name,
                isFolderInTrash: chain.contains { $0.deletedAt != nil },
                deletedAt: deletedAt,
                isLocked: row.isLocked || chain.contains(where: \.isLocked)))
        }
        let folderItems: [TrashItem] = folders
            .filter { $0.deletedAt != nil && !$0.deletedWithParent }
            .compactMap { root in
                guard let deletedAt = root.deletedAt else { return nil }
                let deletedWith = tree.descendantsOf(root.savedId) { $0.deletedWithParent }
                let memoCount = (deletedWith.map(\.savedId) + [root.savedId]).reduce(0) { $0 + (memoCountByFolder[$1] ?? 0) }
                let ancestors = tree.chainOf(root.savedId).dropFirst()
                return .folder(TrashedFolder(
                    folder: root.toModel(itemCount: deletedWith.count + memoCount),
                    folderCount: deletedWith.count,
                    memoCount: memoCount,
                    parentName: ancestors.first?.name,
                    isParentInTrash: ancestors.contains { $0.deletedAt != nil },
                    deletedAt: deletedAt,
                    isLocked: root.isLocked || ancestors.contains(where: \.isLocked)))
            }
        return (memoItems + folderItems).sorted { $0.deletedAt > $1.deletedAt }
    }

    /// メモの元フォルダかその上の階層がゴミ箱にあるか（true なら「フォルダごと復元しますか？」の確認が必要）。
    func isParentFolderInTrash(memoId: Int64) async throws -> Bool {
        try await database.writer.read { db in
            guard let folderId = try MemoDao.findSummaryById(db, id: memoId)?.folderId else { return false }
            return FolderTree(try FolderDao.getAll(db)).chainOf(folderId).contains { $0.deletedAt != nil }
        }
    }

    /// フォルダの上の階層がゴミ箱にあるか（true なら「フォルダごと復元しますか？」の確認が必要）。
    func isParentOfFolderInTrash(folderId: Int64) async throws -> Bool {
        try await database.writer.read { db in
            FolderTree(try FolderDao.getAll(db)).chainOf(folderId).dropFirst().contains { $0.deletedAt != nil }
        }
    }

    /// メモを復元する。上の階層がゴミ箱にある場合は、それらも（一緒に削除された中身ごと）復元する。
    /// 削除直後の「元に戻す」にも使う。
    func restoreMemo(id memoId: Int64, now: Int64) async throws {
        try await database.writer.write { db in
            guard let memo = try MemoDao.findSummaryById(db, id: memoId) else { return }
            if let folderId = memo.folderId {
                try Self.restoreTrashedChain(db, tree: FolderTree(try FolderDao.getAll(db)), folderId: folderId)
                try FolderDao.touchWithAncestors(db, folderIds: [folderId], now: now)
            }
            try MemoDao.restore(db, id: memoId)
        }
    }

    /// フォルダと、一緒に削除された中身（全階層）を復元する。上の階層がゴミ箱にある場合はそれらも復元する。
    /// 削除直後の「元に戻す」にも使う。
    func restoreFolder(id folderId: Int64, now: Int64) async throws {
        try await database.writer.write { db in
            let tree = FolderTree(try FolderDao.getAll(db))
            guard let folder = tree[folderId] else { return }
            try Self.restoreTrashedChain(db, tree: tree, folderId: folderId)
            if let parentId = folder.parentId {
                try FolderDao.touchWithAncestors(db, folderIds: [parentId], now: now)
            }
        }
    }

    /// `folderId` から上の階層をたどり、ゴミ箱に入っている「削除の起点」のフォルダをすべて、
    /// 一緒に削除された中身ごと復元する（途中の「一緒に削除された」フォルダは起点の復元で戻る）。
    private nonisolated static func restoreTrashedChain(_ db: Database, tree: FolderTree, folderId: Int64) throws {
        for root in tree.chainOf(folderId) where root.deletedAt != nil && !root.deletedWithParent {
            let ids = tree.descendantsOf(root.savedId) { $0.deletedWithParent }.map(\.savedId) + [root.savedId]
            try FolderDao.restore(db, ids: ids)
            try MemoDao.restoreDeletedWithFolder(db, folderIds: ids)
        }
    }

    func deleteMemoPermanently(id: Int64) async throws {
        try await database.writer.write { db in try MemoDao.deletePermanently(db, id: id) }
    }

    /// フォルダ完全削除の確認ダイアログ用。一緒に完全削除される中身（全階層、ゴミ箱内のものすべて）の件数。
    func countContentsOfTrashedFolder(id folderId: Int64) async throws -> FolderContents {
        try await database.writer.read { db in
            let descendants = FolderTree(try FolderDao.getAll(db)).descendantsOf(folderId)
            let memoCount = try MemoDao.countInFolders(db, folderIds: descendants.map(\.savedId) + [folderId])
            return FolderContents(folderCount: descendants.count, memoCount: memoCount)
        }
    }

    /// フォルダを完全削除する。中身（ゴミ箱内のものすべて）も CASCADE で完全削除される。
    func deleteFolderPermanently(id: Int64) async throws {
        try await database.writer.write { db in try FolderDao.deletePermanently(db, id: id) }
    }

    /// ゴミ箱を空にする。
    func emptyTrash() async throws {
        try await database.writer.write { db in
            try MemoDao.deleteAllTrashed(db)
            try FolderDao.deleteAllTrashed(db)
        }
    }

    /// 保持期間を過ぎたものを完全削除する（アプリ起動時に呼ぶ）。
    func purgeExpired(now: Int64) async throws {
        let threshold = TrashPolicy.expiryThreshold(now: now)
        try await database.writer.write { db in
            try MemoDao.deleteExpired(db, threshold: threshold)
            try FolderDao.deleteExpired(db, threshold: threshold)
        }
    }
}
