import Foundation
import Observation

/// 設定タブのトップの状態。
struct SettingsUiState: Equatable {
    /// 今のテーマ。読み込み中は nil（どれも選ばれていない状態にする）
    var themeMode: ThemeMode?
}

/// 設定タブのトップ（Android 版の SettingsViewModel にあたる）。テーマはこの画面で直接切り替える。
/// 「表示」「データ」「ゴミ箱」「オープンソースライセンス」は NavigationLink で開き、「プライバシーポリシー」はアプリ内のブラウザで開く（画面側）。
@Observable
final class SettingsViewModel {
    private(set) var uiState = SettingsUiState()

    private let observeThemeMode: ObserveThemeModeUseCase
    private let setThemeMode: SetThemeModeUseCase

    init(observeThemeMode: ObserveThemeModeUseCase, setThemeMode: SetThemeModeUseCase) {
        self.observeThemeMode = observeThemeMode
        self.setThemeMode = setThemeMode
    }

    /// テーマを監視する（画面が出ている間）。
    func observe() async {
        for await mode in observeThemeMode() {
            uiState = SettingsUiState(themeMode: mode)
        }
    }

    /// テーマを選んだとき。保存すると MainViewModel が監視していて、全画面に反映される。
    func onThemeModeSelected(_ mode: ThemeMode) {
        guard mode != uiState.themeMode else { return }
        setThemeMode(mode)
    }
}
