import SwiftUI

/// 設定の「データ」（Android 版の DataSettingsFragment にあたる）。
/// 今のデータサイズと、バックアップ（iCloud バックアップ・Mac や PC へのバックアップ）の説明を出す。
/// iOS のバックアップには上限がないので、Android の「上限 25MB」とバーは出さない（docs/requirements.md）。
struct DataSettingsScreen: View {
    @State private var viewModel: DataSettingsViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeDataSettingsViewModel())
    }

    var body: some View {
        List {
            Section {
                LabeledContent("data_current_size") {
                    if let bytes = viewModel.uiState.dataBytes {
                        Text(DataSizeText.format(bytes))
                            .monospacedDigit()
                            .accessibilityIdentifier("data_size")
                    } else {
                        ProgressView()
                    }
                }
            }
            Section("data_backup_title") {
                Text("data_backup_description_ios")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .navigationTitle("settings_data")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }
}
