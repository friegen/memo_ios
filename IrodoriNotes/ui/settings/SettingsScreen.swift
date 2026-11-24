import SwiftUI

/// 設定タブのトップ（Android 版の SettingsFragment にあたる）。
/// - テーマ（端末に従う / ライト / ダーク）: この画面で直接切り替える
/// - 「表示」「データ」「ゴミ箱」: それぞれの画面を開く
/// - 下の小さな文字: 「オープンソースライセンス」の画面、「プライバシーポリシー」（アプリ内のブラウザ）
/// 「広告のプライバシー設定」（同意が必要な地域の利用者だけ）はステップ11で足す。
struct SettingsScreen: View {
    @Binding var path: NavigationPath
    @State private var viewModel: SettingsViewModel

    init(container: AppContainer, path: Binding<NavigationPath>) {
        _path = path
        _viewModel = State(initialValue: container.makeSettingsViewModel())
    }

    var body: some View {
        List {
            Section("settings_theme") {
                Picker("settings_theme", selection: themeSelection) {
                    Text("theme_system").tag(ThemeMode?.some(.system))
                    Text("theme_light").tag(ThemeMode?.some(.light))
                    Text("theme_dark").tag(ThemeMode?.some(.dark))
                }
                .pickerStyle(.segmented)
                .labelsHidden()
                .accessibilityIdentifier("theme_picker")
            }

            Section {
                NavigationLink(value: AppRoute.displaySettings) {
                    SettingsLinkRow(title: "settings_display", summary: "settings_display_summary")
                }
                .accessibilityIdentifier("settings_display")
                NavigationLink(value: AppRoute.dataSettings) {
                    SettingsLinkRow(title: "settings_data", summary: "settings_data_summary")
                }
                .accessibilityIdentifier("settings_data")
                NavigationLink(value: AppRoute.trash) {
                    SettingsLinkRow(title: "settings_trash", summary: "settings_trash_summary")
                }
                .accessibilityIdentifier("settings_trash")
            } footer: {
                // Android と同じく、右下に小さな文字で
                HStack(spacing: 16) {
                    Spacer()
                    Button("settings_open_source_licenses") {
                        path.append(AppRoute.licenses)
                    }
                    .accessibilityIdentifier("settings_licenses")
                    Button("settings_privacy_policy") {
                        InAppBrowser.open(AppLinks.privacyPolicy)
                    }
                    .accessibilityIdentifier("settings_privacy_policy")
                }
                .font(.footnote)
                .padding(.top, 24)
            }
        }
        .navigationTitle("tab_settings")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.observe() }
    }

    /// テーマの選択。読み込み中（nil）はどれも選ばれていない。
    private var themeSelection: Binding<ThemeMode?> {
        Binding(
            get: { viewModel.uiState.themeMode },
            set: { mode in
                if let mode { viewModel.onThemeModeSelected(mode) }
            })
    }
}

/// 設定の項目の1行: 題名と説明。
private struct SettingsLinkRow: View {
    let title: LocalizedStringKey
    let summary: LocalizedStringKey

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
            Text(summary)
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}
