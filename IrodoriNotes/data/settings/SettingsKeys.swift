import Foundation

/// 設定値（UserDefaults）の保存キー。Android 版の DataStore のキーと同じ名前にしている。
/// enum は rawValue（Android と同じ名前）を文字列で保存する。
nonisolated enum SettingsKeys {
    static let themeMode = "theme_mode"
    static let fontSize = "font_size"
    static let lineSpacing = "line_spacing"

    static let memoTabSortKey = "memo_tab_sort_key"
    static let memoTabSortAsc = "memo_tab_sort_asc"

    static let folderListSortKey = "folder_list_sort_key"
    static let folderListSortAsc = "folder_list_sort_asc"

    static let folderMemoSortKey = "folder_memo_sort_key"
    static let folderMemoSortAsc = "folder_memo_sort_asc"

    // 広告（AdStateRepository）
    static let appLaunchCount = "app_launch_count"
    static let appOpenAdLastShownAt = "app_open_ad_last_shown_at"
    static let subfolderCredits = "subfolder_credits"

    // レビューのお願い（ReviewRepository）
    static let reviewStage = "review_stage"
    static let reviewLikedAtLaunch = "review_liked_at_launch"
}
