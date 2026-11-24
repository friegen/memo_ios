import Foundation
import Observation

/// 設定の「オープンソースライセンス」の状態。
struct LicensesUiState: Equatable {
    var isLoading = true
    var libraries: [OssLibrary] = []
}

/// 設定の「オープンソースライセンス」（Android 版の LicensesViewModel にあたる）。使っているライブラリの一覧。
/// タップすると、そのライセンスの全文の画面を開く（画面側で NavigationLink）。
@Observable
final class LicensesViewModel {
    private(set) var uiState = LicensesUiState()

    private let getOssLibraries: GetOssLibrariesUseCase

    init(getOssLibraries: GetOssLibrariesUseCase) {
        self.getOssLibraries = getOssLibraries
    }

    /// 一覧はアプリの中で変わらないので、開いたときに1回だけ読む。
    func load() async {
        do {
            uiState = LicensesUiState(isLoading: false, libraries: try await getOssLibraries())
        } catch {
            AppLog.error("ライセンスの一覧を読めなかった: \(error)")
            uiState = LicensesUiState(isLoading: false, libraries: [])
        }
    }
}
