import Foundation

/// テーマ。既定は端末の設定に従う。rawValue は保存用（Android と同じ名前）。
nonisolated enum ThemeMode: String, CaseIterable, Sendable {
    case system = "SYSTEM"
    case light = "LIGHT"
    case dark = "DARK"
}

/// メモ編集画面の文字の大きさ（段階選択）。値は Android の sp と同じ数字の pt。
nonisolated enum FontSizeLevel: String, CaseIterable, Sendable {
    case small = "SMALL"
    case medium = "MEDIUM"
    case large = "LARGE"
    case extraLarge = "EXTRA_LARGE"

    var sizePt: Double {
        switch self {
        case .small: 14
        case .medium: 16
        case .large: 20
        case .extraLarge: 24
        }
    }
}

/// メモ編集画面の行間（段階選択）。行の高さに掛ける倍率。
nonisolated enum LineSpacingLevel: String, CaseIterable, Sendable {
    case narrow = "NARROW"
    case normal = "NORMAL"
    case wide = "WIDE"
    case extraWide = "EXTRA_WIDE"

    var multiplier: Double {
        switch self {
        case .narrow: 1.0
        case .normal: 1.2
        case .wide: 1.5
        case .extraWide: 1.8
        }
    }
}

/// メモ編集画面に反映する表示設定。
nonisolated struct EditorSettings: Equatable, Sendable {
    var fontSize: FontSizeLevel = .medium
    var lineSpacing: LineSpacingLevel = .normal
}
