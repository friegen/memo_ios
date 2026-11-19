import Foundation
import Observation

/// メイン画面（下タブ）の状態。
struct MainUiState: Equatable {
    var themeMode: ThemeMode
}

/// メイン画面の ViewModel（Android 版の MainViewModel にあたる）。今はテーマだけ。
@Observable
final class MainViewModel {
    private(set) var uiState: MainUiState

    private let observeThemeMode: ObserveThemeModeUseCase

    init(getThemeMode: GetThemeModeUseCase, observeThemeMode: ObserveThemeModeUseCase) {
        self.observeThemeMode = observeThemeMode
        // 最初の画面から保存しているテーマで出す（ちらつかないように、すぐに読む）
        uiState = MainUiState(themeMode: getThemeMode())
    }

    /// テーマ設定を監視する（画面が出ている間。View の `.task` から呼ぶ）。
    func observe() async {
        for await mode in observeThemeMode() {
            uiState.themeMode = mode
        }
    }
}
