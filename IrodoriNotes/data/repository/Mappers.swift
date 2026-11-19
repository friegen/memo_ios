import Foundation

// DB のレコード → ドメインモデル。画面側にレコードを出さない（Android 版の Mappers.kt にあたる）。

nonisolated extension MemoRecord {
    func toModel(lockedFolderIds: [Int64] = []) -> Memo {
        Memo(
            id: savedId, folderId: folderId, html: html, plainText: plainText, charCount: charCount,
            createdAt: createdAt, updatedAt: updatedAt, isLocked: isLocked, lockedFolderIds: lockedFolderIds)
    }
}

nonisolated extension MemoSummaryRow {
    func toModel() -> MemoSummary {
        MemoSummary(
            id: id, folderId: folderId, firstLine: firstLine, charCount: charCount,
            createdAt: createdAt, updatedAt: updatedAt, isLocked: isLocked, isPinned: isPinned)
    }
}

nonisolated extension FolderWithItemCountRow {
    func toModel() -> Folder { folder.toModel(itemCount: itemCount) }
}

nonisolated extension FolderRecord {
    func toModel(itemCount: Int) -> Folder {
        Folder(
            id: savedId, parentId: parentId, name: name, color: FolderColor.fromKey(colorKey),
            createdAt: createdAt, updatedAt: updatedAt, itemCount: itemCount, isLocked: isLocked, isPinned: isPinned)
    }
}
