import Foundation
import Observation

/// 設定の「データ」画面の状態。
struct DataSettingsUiState: Equatable {
    /// 今のデータサイズ（バイト）。調べ終わるまでは nil
    var dataBytes: Int64?
}

/// 設定の「データ」画面（Android 版の DataSettingsViewModel にあたる）。今のデータサイズを表示する。
/// iOS のバックアップには上限がないので、Android の「上限 25MB」のバーは出さない（docs/requirements.md）。
@Observable
final class DataSettingsViewModel {
    private(set) var uiState = DataSettingsUiState()

    private let getDataUsage: GetDataUsageUseCase

    init(getDataUsage: GetDataUsageUseCase) {
        self.getDataUsage = getDataUsage
    }

    /// この画面を開いている間はデータが変わらないので、開いたときに1回だけ調べる。
    func load() async {
        uiState = DataSettingsUiState(dataBytes: await getDataUsage())
    }
}
