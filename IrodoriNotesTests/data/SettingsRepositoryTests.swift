import Foundation
import Testing
@testable import IrodoriNotes

/// 設定の Repository（Android 版の SettingsRepositoryTest と同じ内容）。
struct SettingsRepositoryTests {
    let defaults: UserDefaults
    let repository: SettingsRepository

    init() throws {
        // テストごとに別の保存先を使う（アプリの設定を汚さない）
        let suiteName = "SettingsRepositoryTests-\(UUID().uuidString)"
        defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        repository = SettingsRepository(defaults: defaults)
    }

    @Test func defaults_areAndroidDefaults() async throws {
        #expect(try await repository.observeThemeMode().firstValue() == .system)
        #expect(try await repository.observeEditorSettings().firstValue() == EditorSettings(fontSize: .medium, lineSpacing: .normal))
        #expect(try await repository.observeMemoTabSort().firstValue() == MemoSort(key: .updatedAt, ascending: false))
        #expect(try await repository.observeFolderMemoSort().firstValue() == MemoSort(key: .updatedAt, ascending: false))
        #expect(try await repository.observeFolderListSort().firstValue() == FolderSort(key: .updatedAt, ascending: false))
    }

    @Test func savesEachSetting() async throws {
        repository.setThemeMode(.dark)
        repository.setFontSize(.extraLarge)
        repository.setLineSpacing(.wide)

        #expect(try await repository.observeThemeMode().firstValue() == .dark)
        #expect(repository.themeMode == .dark)
        #expect(try await repository.observeEditorSettings().firstValue() == EditorSettings(fontSize: .extraLarge, lineSpacing: .wide))
    }

    @Test func threeSortSettingsAreIndependent() async throws {
        repository.setMemoTabSort(MemoSort(key: .charCount, ascending: true))
        repository.setFolderMemoSort(MemoSort(key: .createdAt, ascending: false))
        repository.setFolderListSort(FolderSort(key: .name, ascending: true))

        #expect(try await repository.observeMemoTabSort().firstValue() == MemoSort(key: .charCount, ascending: true))
        #expect(try await repository.observeFolderMemoSort().firstValue() == MemoSort(key: .createdAt, ascending: false))
        #expect(try await repository.observeFolderListSort().firstValue() == FolderSort(key: .name, ascending: true))
    }

    @Test func unknownStoredValueFallsBackToDefault() async throws {
        defaults.set("NO_SUCH_MODE", forKey: SettingsKeys.themeMode)

        #expect(try await repository.observeThemeMode().firstValue() == .system)
    }

    /// 保存する値は Android の DataStore と同じキー・同じ名前（将来バックアップを共通にしやすくするため）。
    @Test func storedValuesUseAndroidNames() {
        repository.setThemeMode(.dark)
        repository.setFontSize(.extraLarge)
        repository.setMemoTabSort(MemoSort(key: .charCount, ascending: true))

        #expect(defaults.string(forKey: "theme_mode") == "DARK")
        #expect(defaults.string(forKey: "font_size") == "EXTRA_LARGE")
        #expect(defaults.string(forKey: "memo_tab_sort_key") == "CHAR_COUNT")
        #expect(defaults.bool(forKey: "memo_tab_sort_asc"))
    }

    /// 値が変わると、監視している側に新しい値が流れる。同じ値では流れない。
    @Test func observeThemeMode_emitsOnlyWhenChanged() async throws {
        var iterator = repository.observeThemeMode().makeAsyncIterator()
        #expect(await iterator.next() == .system)

        repository.setThemeMode(.system) // 同じ値（流れない）
        repository.setThemeMode(.light)

        #expect(await iterator.next() == .light)
    }
}
