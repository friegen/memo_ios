import StoreKit
import SwiftUI

/// 下タブの種類。
enum MainTab: Hashable {
    case memo, folder, settings
}

/// メイン画面: 下タブ3つ（メモ / フォルダ / 設定）。Android 版の MainActivity にあたる。
///
/// タブを押すと、前に見ていた画面ではなく、いつもそのタブのトップを開く（Android 版 v1.8）。
/// 下タブの上にバナー広告（編集画面が出ている間は隠す。編集画面は自分のバナーを出す）。
/// 新しく起動したときは、起動画面と同じ見た目で覆ったまま、広告の同意の確認とアプリ起動広告を待つ（`AdsManager`）。
/// アプリを開いたとき（新しく起動した・バックグラウンドから戻った）は、レビューのお願いがあれば出す（`ReviewPolicy`）。
struct MainView: View {
    let container: AppContainer

    @State private var viewModel: MainViewModel
    @State private var selectedTab: MainTab = .memo
    @State private var memoPath = NavigationPath()
    @State private var folderPath = NavigationPath()
    @State private var settingsPath = NavigationPath()
    /// バックグラウンドに回ったことがあるか（戻ってきたときにアプリ起動広告を出すため）
    @State private var wasInBackground = false
    /// 「気に入っていただけましたか？」を出しているか
    @State private var isFavoriteQuestionShown = false
    /// 出しているお礼の文（「気に入った」「いまひとつ」へのお礼）
    @State private var thanksMessage: LocalizedStringKey?
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.requestReview) private var requestReview

    init(container: AppContainer) {
        self.container = container
        _viewModel = State(initialValue: container.makeMainViewModel())
    }

    var body: some View {
        TabView(selection: tabSelection) {
            Tab("tab_memo", systemImage: "note.text", value: MainTab.memo) {
                NavigationStack(path: $memoPath) {
                    MemoListScreen(container: container, path: $memoPath)
                        .navigationDestination(for: AppRoute.self) { destination($0, path: $memoPath) }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { mainBanner(for: .memo) }
            }
            Tab("tab_folder", systemImage: "folder", value: MainTab.folder) {
                NavigationStack(path: $folderPath) {
                    FolderListScreen(container: container, path: $folderPath)
                        .navigationDestination(for: AppRoute.self) { destination($0, path: $folderPath) }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { mainBanner(for: .folder) }
            }
            Tab("tab_settings", systemImage: "gearshape", value: MainTab.settings) {
                NavigationStack(path: $settingsPath) {
                    SettingsScreen(container: container, path: $settingsPath)
                        .navigationDestination(for: AppRoute.self) { destination($0, path: $settingsPath) }
                }
                .safeAreaInset(edge: .bottom, spacing: 0) { mainBanner(for: .settings) }
            }
        }
        .overlay {
            // 新しく起動したとき、広告の準備を待つ間（最大3秒）。iOS の起動画面と同じ見た目
            if container.ads.isSplashVisible { LaunchCover() }
        }
        .overlay {
            // ロックした中身を表示している間は、アプリの切り替え画面に中身を映さない（アプリから離れかけたら覆う）
            if container.lockSession.protectedScreenCount > 0, scenePhase != .active, !container.lockSession.isAuthenticating {
                PrivacyCover()
            }
        }
        .onChange(of: scenePhase) { _, phase in
            // アプリから離れたら、ロックしたものをすべてロックし直す（Face ID の画面・通知センターでは .inactive なのでロックしない）
            if phase == .background {
                container.lockSession.onEnterBackground()
                wasInBackground = true
            } else if phase == .active, wasInBackground {
                // バックグラウンドから戻った（アプリの中の画面の行き来・通知センターでは出さない）
                wasInBackground = false
                Task {
                    await container.ads.onForeground() // アプリ起動広告を出したら、閉じるまで待つ
                    viewModel.onAppOpened()
                }
            }
        }
        .task {
            await container.ads.handleColdLaunch() // 起動画面と同じ見た目の覆いが外れるまで
            viewModel.onAppOpened()
        }
        .task {
            for await event in viewModel.events() { handle(event) }
        }
        .alert("review_favorite_title", isPresented: $isFavoriteQuestionShown) {
            Button("review_favorite_yes") { viewModel.onFavoriteAnswered(liked: true) }
            Button("review_favorite_no") { viewModel.onFavoriteAnswered(liked: false) }
        } message: {
            Text("review_favorite_message")
        }
        // お礼（題名なし。Android と同じ）。質問とは別の状態にして、質問が閉じる途中でも消されないようにする
        .alert(
            Text(verbatim: ""),
            isPresented: Binding(get: { thanksMessage != nil }, set: { if !$0 { thanksMessage = nil } }),
            presenting: thanksMessage
        ) { _ in
            Button("action_ok", role: .cancel) {}
        } message: { message in
            Text(message)
        }
        .background(WindowThemeApplier(mode: viewModel.uiState.themeMode))
        .task { await viewModel.observe() }
    }

    private func handle(_ event: MainEvent) {
        switch event {
        case .askFavorite:
            isFavoriteQuestionShown = true
        case .thankForLiking:
            thanksMessage = "review_liked_message"
        case .thankForFeedback:
            thanksMessage = "review_disliked_message"
        case .requestReview:
            // iOS のレビューのダイアログ（その場で星を付けられる）。出すかどうか・回数は iOS が決める（1年に3回まで）。
            // Apple の決まりで、アプリ独自の「レビューを書く／今はしない」は出さない（docs/requirements.md）
            requestReview()
        }
    }

    /// 下タブの上のバナー広告。編集画面が出ている間は隠す（作り直さない）。
    /// タブの中身は、そのタブを初めて開いたときに作られ（TabView の決まり）、バナーは画面に出てから読み込むので、
    /// 開いていないタブの広告は読み込まない。
    private func mainBanner(for tab: MainTab) -> some View {
        BannerAdSlot(adUnitID: AdUnitIDs.bannerMain, ads: container.ads, isHidden: container.ads.editorScreenCount > 0)
    }

    /// タブの中で開く画面。
    /// - Parameter path: そのタブの画面の積み重ね（開いた先の画面がさらに画面を開くのに使う）
    @ViewBuilder
    private func destination(_ route: AppRoute, path: Binding<NavigationPath>) -> some View {
        switch route {
        case .editor(let memoId, let folderId):
            MemoEditScreen(container: container, memoId: memoId, folderId: folderId)
        case .folder(let folderId):
            FolderDetailScreen(container: container, folderId: folderId, path: path)
        case .displaySettings:
            DisplaySettingsScreen(container: container)
        case .dataSettings:
            DataSettingsScreen(container: container)
        case .trash:
            TrashScreen(container: container)
        case .licenses:
            LicensesScreen(container: container)
        case .license(let library):
            LicenseDetailScreen(library: library)
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
