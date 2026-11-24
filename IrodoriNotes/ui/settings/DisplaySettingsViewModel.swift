import Foundation
import Observation

/// 設定の「表示」画面の状態。
struct DisplaySettingsUiState: Equatable {
    /// 今の文字の大きさ・行間。読み込み中は nil
    var settings: EditorSettings?
}

/// 設定の「表示」画面（Android 版の DisplaySettingsViewModel にあたる）。
/// メモ編集画面の文字の大きさ・行間を段階で選び、サンプルで見た目を確かめる。
@Observable
final class DisplaySettingsViewModel {
    private(set) var uiState = DisplaySettingsUiState()

    private let observeEditorSettings: ObserveEditorSettingsUseCase
    private let setFontSize: SetFontSizeUseCase
    private let setLineSpacing: SetLineSpacingUseCase

    init(observeEditorSettings: ObserveEditorSettingsUseCase, setFontSize: SetFontSizeUseCase, setLineSpacing: SetLineSpacingUseCase) {
        self.observeEditorSettings = observeEditorSettings
        self.setFontSize = setFontSize
        self.setLineSpacing = setLineSpacing
    }

    func observe() async {
        for await settings in observeEditorSettings() {
            uiState = DisplaySettingsUiState(settings: settings)
        }
    }

    func onFontSizeSelected(_ level: FontSizeLevel) {
        guard level != uiState.settings?.fontSize else { return }
        setFontSize(level)
    }

    func onLineSpacingSelected(_ level: LineSpacingLevel) {
        guard level != uiState.settings?.lineSpacing else { return }
        setLineSpacing(level)
    }
}
