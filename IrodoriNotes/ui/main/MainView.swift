import SwiftUI

/// 下タブの種類。
enum MainTab: Hashable {
    case memo, folder, settings
}

/// メイン画面: 下タブ3つ（メモ / フォルダ / 設定）。Android 版の MainActivity にあたる。
///
/// タブを押すと、前に見ていた画面ではなく、いつもそのタブのトップを開く（Android 版 v1.8）。
struct MainView: View {
    let container: AppContainer

    @State private var viewModel: MainViewModel
    @State private var selectedTab: MainTab = .memo
    @State private var memoPath = NavigationPath()
    @State private var folderPath = NavigationPath()
    @State private var settingsPath = NavigationPath()

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: container.makeMainViewModel())
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("tab_memo", systemImage: "note.text", value: MainTab.memo) {
                NavigationStack(path: $memoPath) {
                    MemoListScreen(container: container, path: $memoPath)
                        .navigationDestination(for: AppRoute.self, destination: destination)
                }
            }
            Tab("tab_folder", systemImage: "folder", value: MainTab.folder) {
                NavigationStack(path: $folderPath) {
                    FolderListScreen(container: container, path: $folderPath)
                        .navigationDestination(for: AppRoute.self, destination: destination)
                }
            }
            Tab("tab_settings", systemImage: "gearshape", value: MainTab.settings) {
                NavigationStack(path: $settingsPath) {
                    SettingsScreen()
                }
            }
        }
        .background(WindowThemeApplier(mode: viewModel.uiState.themeMode))
        .task { await viewModel.observe() }
    }

    /// タブの中で開く画面。
    @ViewBuilder
    private func destination(_ route: AppRoute) -> some View {
        switch route {
        case .editor(let memoId, let folderId):
            MemoEditScreen(container: container, memoId: memoId, folderId: folderId)
        case .folder(let folderId):
            FolderDetailScreen(container: container, folderId: folderId)
        }
    }

    /// タブを選んだら、そのタブの画面の積み重ねを消してトップに戻す（今いるタブをもう一度押したときも）。
    private var tabSelection: Binding<MainTab> {
        Binding(
            get: { selectedTab },
            set: { tab in
                switch tab {
                case .memo: memoPath = NavigationPath()
                case .folder: folderPath = NavigationPath()
                case .settings: settingsPath = NavigationPath()
                }
                selectedTab = tab
            })
    }
}
