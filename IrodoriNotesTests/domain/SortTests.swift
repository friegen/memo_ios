import Foundation
import Testing
@testable import IrodoriNotes

/// 並び替え（Android 版の SortTest と同じ内容）。
struct SortTests {

    private func memo(id: Int64, created: Int64, updated: Int64, chars: Int, pinned: Bool = false) -> MemoSummary {
        MemoSummary(id: id, folderId: nil, firstLine: "", charCount: chars, createdAt: created, updatedAt: updated, isPinned: pinned)
    }

    private func folder(
        id: Int64, name: String, created: Int64 = 0, updated: Int64 = 0, count: Int = 0, pinned: Bool = false
    ) -> Folder {
        Folder(id: id, parentId: nil, name: name, color: .default, createdAt: created, updatedAt: updated, itemCount: count, isPinned: pinned)
    }

    private var memos: [MemoSummary] {
        [
            memo(id: 1, created: 100, updated: 300, chars: 10),
            memo(id: 2, created: 200, updated: 200, chars: 30),
            memo(id: 3, created: 300, updated: 100, chars: 20),
        ]
    }

    @Test func pinnedItemsComeFirst_inTheSameOrder() {
        let withPins = memos.map { $0.id == 3 || $0.id == 2 ? memo(id: $0.id, created: $0.createdAt, updated: $0.updatedAt, chars: $0.charCount, pinned: true) : $0 }
        // ピン留めした 2・3 が上（その中は同じ並び順）、その下に 1
        #expect(MemoSort().sort(withPins).map(\.id) == [2, 3, 1])
        #expect(MemoSort(key: .updatedAt, ascending: true).sort(withPins).map(\.id) == [3, 2, 1])

        let folders = [folder(id: 1, name: "あ"), folder(id: 2, name: "い", pinned: true), folder(id: 3, name: "う")]
        #expect(FolderSort(key: .name, ascending: true).sort(folders, locale: Locale(identifier: "ja_JP")).map(\.id) == [2, 1, 3])
    }

    @Test func memoSort_default_isUpdatedAtDescending() {
        #expect(MemoSort().sort(memos).map(\.id) == [1, 2, 3])
    }

    @Test func memoSort_eachKeyAndDirection() {
        #expect(MemoSort(key: .createdAt, ascending: true).sort(memos).map(\.id) == [1, 2, 3])
        #expect(MemoSort(key: .createdAt, ascending: false).sort(memos).map(\.id) == [3, 2, 1])
        #expect(MemoSort(key: .updatedAt, ascending: true).sort(memos).map(\.id) == [3, 2, 1])
        #expect(MemoSort(key: .charCount, ascending: true).sort(memos).map(\.id) == [1, 3, 2])
        #expect(MemoSort(key: .charCount, ascending: false).sort(memos).map(\.id) == [2, 3, 1])
    }

    @Test func memoSort_tiesAreOrderedByNewestId() {
        let tied = [memo(id: 1, created: 0, updated: 0, chars: 5), memo(id: 2, created: 0, updated: 0, chars: 5), memo(id: 3, created: 0, updated: 0, chars: 5)]
        #expect(MemoSort(key: .charCount, ascending: true).sort(tied).map(\.id) == [3, 2, 1])
        #expect(MemoSort(key: .charCount, ascending: false).sort(tied).map(\.id) == [3, 2, 1])
    }

    @Test func folderSort_eachKey() {
        let folders = [
            folder(id: 1, name: "b", created: 100, updated: 300, count: 2),
            folder(id: 2, name: "c", created: 200, updated: 100, count: 3),
            folder(id: 3, name: "a", created: 300, updated: 200, count: 1),
        ]
        #expect(FolderSort().sort(folders).map(\.id) == [1, 3, 2])
        #expect(FolderSort(key: .createdAt, ascending: true).sort(folders).map(\.id) == [1, 2, 3])
        #expect(FolderSort(key: .name, ascending: true).sort(folders).map(\.id) == [3, 1, 2])
        #expect(FolderSort(key: .itemCount, ascending: false).sort(folders).map(\.id) == [2, 1, 3])
    }

    @Test func folderSort_nameUsesLocaleAwareOrder() {
        let folders = [folder(id: 1, name: "かきくけこ"), folder(id: 2, name: "あいうえお"), folder(id: 3, name: "さしすせそ")]
        #expect(
            FolderSort(key: .name, ascending: true).sort(folders, locale: Locale(identifier: "ja_JP")).map(\.name)
                == ["あいうえお", "かきくけこ", "さしすせそ"])
    }

    @Test func folderColor_unknownKeyFallsBackToDefault() {
        #expect(FolderColor.fromKey("blue") == .blue)
        #expect(FolderColor.fromKey("no-such-color") == .default)
        #expect(FolderColor.fromKey(nil) == .default)
    }

    @Test func folderColor_keysAreSameAsAndroid() {
        #expect(FolderColor.allCases.map(\.rawValue)
            == ["default", "red", "orange", "yellow", "green", "teal", "blue", "indigo", "purple", "pink"])
    }

    @Test func memoSummary_isUpdated() {
        var m = memo(id: 1, created: 10, updated: 10, chars: 0)
        #expect(!m.isUpdated)
        m.updatedAt = 11
        #expect(m.isUpdated)
    }
}
