import SwiftUI

/// 設定の「オープンソースライセンス」（Android 版の LicensesFragment にあたる）。使っているライブラリの一覧。
/// 行をタップすると、そのライセンスの全文の画面を開く。
struct LicensesScreen: View {
    @State private var viewModel: LicensesViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeLicensesViewModel())
    }

    var body: some View {
        List(viewModel.uiState.libraries) { library in
            NavigationLink(value: AppRoute.license(library)) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(library.name)
                    Text(detail(of: library))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 2)
            }
            .accessibilityIdentifier("license_row")
        }
        .overlay {
            if viewModel.uiState.isLoading { ProgressView() }
        }
        .navigationTitle("licenses_title")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
    }

    /// 「7.12.0 · MIT License」（版が分からなければライセンス名だけ）。
    private func detail(of library: OssLibrary) -> String {
        [library.version, library.licenseName].compactMap { $0 }.joined(separator: L10n.string("license_detail_separator"))
    }
}

/// ライセンスの全文。
struct LicenseDetailScreen: View {
    let library: OssLibrary

    var body: some View {
        ScrollView {
            Text(library.licenseText.isEmpty ? L10n.string("license_no_text") : library.licenseText)
                .font(.footnote)
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
                .accessibilityIdentifier("license_text")
        }
        .titleAndSubtitle(library.name, subtitle: library.licenseName)
        .navigationBarTitleDisplayMode(.inline)
    }
}
