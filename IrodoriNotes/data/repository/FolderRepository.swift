import Foundation
import GRDB

/// 有効な（ゴミ箱に入っていない）フォルダの取得・作成・変更・ゴミ箱への移動。
/// フォルダの中にフォルダを作れる（最大 `FolderPolicy.maxDepth` 階層）。ゴミ箱の中の操作は `TrashRepository`。
final class FolderRepository {
    private let database: AppDatabase

    init(database: AppDatabase) {
        self.database = database
    }

    /// フォルダタブ直下の有効なフォルダ（並び替えは呼び出し側）。
    func observeRootFolders() -> AsyncThrowingStream<[Folder], any Error> {
        database.observe { db in try FolderDao.rootFolders(db).map { $0.toModel() } }
    }

    /// あるフォルダの直下の有効なフォルダ（並び替えは呼び出し側）。
    func observeChildFolders(parentId: Int64) -> AsyncThrowingStream<[Folder], any Error> {
        database.observe { db in try FolderDao.childFolders(db, parentId: parentId).map { $0.toModel() } }
    }

    /// 有効なフォルダを1件監視。ゴミ箱に入った・存在しない場合は nil。
    func observeFolder(id: Int64) -> AsyncThrowingStream<Folder?, any Error> {
        database.observe { db in
            guard let row = try FolderDao.folderWithItemCount(db, id: id), row.folder.deletedAt == nil else { return nil }
            return row.toModel()
        }
    }

    /// フォルダタブ直下から、指定したフォルダまでの階層（先頭がフォルダタブ直下、最後が指定したフォルダ）。
    /// ナビゲーションバーの「趣味 › 読書」表示や、階層の深さ（= 要素数）の判定に使う。
    func getPath(id: Int64) async throws -> [FolderPathEntry] {
        try await database.writer.read { db in
            FolderTree(try FolderDao.getAll(db)).chainOf(id).reversed()
                .map { FolderPathEntry(id: $0.savedId, name: $0.name, isLocked: $0.isLocked) }
        }
    }

    /// 有効なフォルダすべてを木の順（親の直後にその中のフォルダ）に並べた一覧。メモの移動先を選ぶのに使う。
    /// 同じ階層は名前順（端末の言語に合わせた順）。
    func getFolderTree(locale: Locale = .current) async throws -> [FolderTreeEntry] {
        let active = try await database.writer.read { db in
            try FolderDao.getAll(db).filter { $0.deletedAt == nil }
        }
        let childrenByParent = Dictionary(grouping: active, by: \.parentId)
        var result: [FolderTreeEntry] = []
        func visit(parentId: Int64?, depth: Int) {
            let children = (childrenByParent[parentId] ?? [])
                .sorted { compareNames($0.name, $1.name, locale: locale) == .orderedAscending }
            for folder in children {
                result.append(FolderTreeEntry(
                    id: folder.savedId, name: folder.name, color: FolderColor.fromKey(folder.colorKey), depth: depth))
                visit(parentId: folder.savedId, depth: depth + 1)
            }
        }
        visit(parentId: nil, depth: 1)
        return result
    }

    /// フォルダを作る。親フォルダとその上の階層の更新日も進める（中身の追加のため）。
    /// - Parameter parentId: nil ならフォルダタブ直下
    /// - Returns: 作成したフォルダの id
    /// - Throws: `FolderError.depthLimitReached`（親フォルダがすでに最大の階層にある場合。画面側で作れないようにすること）
    func createFolder(parentId: Int64?, name: String, color: FolderColor, now: Int64) async throws -> Int64 {
        try await database.writer.write { db in
            if let parentId {
                let depth = FolderTree(try FolderDao.getAll(db)).depthOf(parentId)
                guard depth < FolderPolicy.maxDepth else { throw FolderError.depthLimitReached }
            }
            let id = try FolderDao.insert(db, FolderRecord(
                parentId: parentId, name: name, colorKey: color.rawValue, createdAt: now, updatedAt: now))
            if let parentId {
                try FolderDao.touchWithAncestors(db, folderIds: [parentId], now: now)
            }
            return id
        }
    }

    /// 名前・色の変更。更新日は変えない。
    func updateFolder(id: Int64, name: String, color: FolderColor) async throws {
        try await database.writer.write { db in
            try FolderDao.updateNameAndColor(db, id: id, name: name, colorKey: color.rawValue)
        }
    }

    /// ロックの付け外し（名前・色と同じく、更新日は変えない）。
    func setLocked(id: Int64, locked: Bool) async throws {
        try await database.writer.write { db in try FolderDao.setLocked(db, id: id, locked: locked) }
    }

    /// ピン留めの付け外し。中身は変わらないので、更新日は進めない。
    func setPinned(id: Int64, pinned: Bool) async throws {
        try await database.writer.write { db in try FolderDao.setPinned(db, id: id, pinned: pinned) }
    }

    /// 削除の確認ダイアログ用。一緒にゴミ箱へ移る中身（全階層の有効なフォルダ・メモ）の件数。
    func countContents(id: Int64) async throws -> FolderContents {
        try await database.writer.read { db in
            let descendants = FolderTree(try FolderDao.getAll(db)).descendantsOf(id) { $0.deletedAt == nil }
            let memoCount = try MemoDao.countActiveInFolders(db, folderIds: descendants.map(\.savedId) + [id])
            return FolderContents(folderCount: descendants.count, memoCount: memoCount)
        }
    }

    /// フォルダと中身（全階層の有効なフォルダ・メモ）をゴミ箱へ。
    /// 中身には「上のフォルダと一緒に削除された」印を付け、先に単体で削除されていたものと区別する。
    /// 親フォルダとその上の階層の更新日も進める。元に戻すときは `TrashRepository.restoreFolder`。
    func moveToTrash(id: Int64, now: Int64) async throws {
        try await database.writer.write { db in
            let tree = FolderTree(try FolderDao.getAll(db))
            guard let folder = tree[id] else { return }
            let descendantIds = tree.descendantsOf(id) { $0.deletedAt == nil }.map(\.savedId)

            try FolderDao.moveToTrash(db, id: id, deletedAt: now)
            try FolderDao.moveToTrashWithParent(db, ids: descendantIds, deletedAt: now)
            try MemoDao.moveToTrashWithFolder(db, folderIds: descendantIds + [id], deletedAt: now)
            if let parentId = folder.parentId {
                try FolderDao.touchWithAncestors(db, folderIds: [parentId], now: now)
            }
        }
    }
}
