import Foundation

/// 設定値（UserDefaults）の読み書き。Android 版の SettingsRepository（DataStore）にあたる。
/// 未設定や不正な値は既定値として扱う。
/// 並び順はメモタブ・フォルダ一覧・フォルダ内のメモ（全フォルダ共通）の3つを別々に持つ。
final class SettingsRepository {
    private let defaults: UserDefaults

    /// - Parameter defaults: テストでは `UserDefaults(suiteName:)` の別の保存先を渡す
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    // MARK: テーマ

    var themeMode: ThemeMode { Self.themeMode(defaults) }

    func observeThemeMode() -> AsyncStream<ThemeMode> { observe(Self.themeMode) }

    func setThemeMode(_ mode: ThemeMode) {
        defaults.set(mode.rawValue, forKey: SettingsKeys.themeMode)
    }

    // MARK: メモ編集画面の表示

    var editorSettings: EditorSettings { Self.editorSettings(defaults) }

    func observeEditorSettings() -> AsyncStream<EditorSettings> { observe(Self.editorSettings) }

    func setFontSize(_ level: FontSizeLevel) {
        defaults.set(level.rawValue, forKey: SettingsKeys.fontSize)
    }

    func setLineSpacing(_ level: LineSpacingLevel) {
        defaults.set(level.rawValue, forKey: SettingsKeys.lineSpacing)
    }

    // MARK: 並び順

    func observeMemoTabSort() -> AsyncStream<MemoSort> { observe(Self.memoTabSort) }

    func setMemoTabSort(_ sort: MemoSort) {
        defaults.set(sort.key.rawValue, forKey: SettingsKeys.memoTabSortKey)
        defaults.set(sort.ascending, forKey: SettingsKeys.memoTabSortAsc)
    }

    func observeFolderMemoSort() -> AsyncStream<MemoSort> { observe(Self.folderMemoSort) }

    func setFolderMemoSort(_ sort: MemoSort) {
        defaults.set(sort.key.rawValue, forKey: SettingsKeys.folderMemoSortKey)
        defaults.set(sort.ascending, forKey: SettingsKeys.folderMemoSortAsc)
    }

    func observeFolderListSort() -> AsyncStream<FolderSort> { observe(Self.folderListSort) }

    func setFolderListSort(_ sort: FolderSort) {
        defaults.set(sort.key.rawValue, forKey: SettingsKeys.folderListSortKey)
        defaults.set(sort.ascending, forKey: SettingsKeys.folderListSortAsc)
    }

    // MARK: 読み取り（未設定・不正な値は既定値）

    private nonisolated static func themeMode(_ defaults: UserDefaults) -> ThemeMode {
        enumValue(defaults, SettingsKeys.themeMode) ?? .system
    }

    private nonisolated static func editorSettings(_ defaults: UserDefaults) -> EditorSettings {
        EditorSettings(
            fontSize: enumValue(defaults, SettingsKeys.fontSize) ?? .medium,
            lineSpacing: enumValue(defaults, SettingsKeys.lineSpacing) ?? .normal)
    }

    private nonisolated static func memoTabSort(_ defaults: UserDefaults) -> MemoSort {
        memoSort(defaults, key: SettingsKeys.memoTabSortKey, asc: SettingsKeys.memoTabSortAsc)
    }

    private nonisolated static func folderMemoSort(_ defaults: UserDefaults) -> MemoSort {
        memoSort(defaults, key: SettingsKeys.folderMemoSortKey, asc: SettingsKeys.folderMemoSortAsc)
    }

    private nonisolated static func folderListSort(_ defaults: UserDefaults) -> FolderSort {
        let fallback = FolderSort()
        return FolderSort(
            key: enumValue(defaults, SettingsKeys.folderListSortKey) ?? fallback.key,
            ascending: defaults.object(forKey: SettingsKeys.folderListSortAsc) as? Bool ?? fallback.ascending)
    }

    private nonisolated static func memoSort(_ defaults: UserDefaults, key: String, asc: String) -> MemoSort {
        let fallback = MemoSort()
        return MemoSort(
            key: enumValue(defaults, key) ?? fallback.key,
            ascending: defaults.object(forKey: asc) as? Bool ?? fallback.ascending)
    }

    private nonisolated static func enumValue<T: RawRepresentable>(_ defaults: UserDefaults, _ key: String) -> T?
    where T.RawValue == String {
        defaults.string(forKey: key).flatMap(T.init(rawValue:))
    }

    /// 今の値を流し、その後は値が変わるたびに流す（Android の DataStore の Flow ＋ distinctUntilChanged にあたる）。
    private func observe<T: Equatable & Sendable>(_ read: @escaping @Sendable (UserDefaults) -> T) -> AsyncStream<T> {
        AsyncStream { continuation in
            // このクラスはメインスレッドで動くので、UserDefaults もメインスレッドで読む
            let task = Task { @MainActor [self] in
                var last = read(defaults)
                continuation.yield(last)
                // どの UserDefaults の変更でも知らせが来る（object に UserDefaults を渡せないため）。値が変わったときだけ流す
                for await _ in NotificationCenter.default.notifications(named: UserDefaults.didChangeNotification) {
                    let value = read(defaults)
                    if value != last {
                        last = value
                        continuation.yield(value)
                    }
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
