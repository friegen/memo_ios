import SwiftUI
import UIKit

/// 設定の「表示」（Android 版の DisplaySettingsFragment にあたる）。
/// メモ編集画面の文字の大きさ・行間を4段階から選ぶ（スライダーの目盛り = 段階）。
/// 選ぶとすぐ保存し、サンプルに編集画面と同じ見た目で反映する。
struct DisplaySettingsScreen: View {
    @State private var viewModel: DisplaySettingsViewModel

    init(container: AppContainer) {
        _viewModel = State(initialValue: container.makeDisplaySettingsViewModel())
    }

    var body: some View {
        let settings = viewModel.uiState.settings
        List {
            Section {
                StepSlider(
                    title: "settings_font_size",
                    levels: FontSizeLevel.allCases,
                    selected: settings?.fontSize,
                    label: \.labelKey,
                    onSelect: viewModel.onFontSizeSelected)
                .accessibilityIdentifier("font_size_slider")
                StepSlider(
                    title: "settings_line_spacing",
                    levels: LineSpacingLevel.allCases,
                    selected: settings?.lineSpacing,
                    label: \.labelKey,
                    onSelect: viewModel.onLineSpacingSelected)
                .accessibilityIdentifier("line_spacing_slider")
            } footer: {
                Text("settings_display_note")
            }

            if let settings {
                Section("settings_sample") {
                    MemoSampleText(text: L10n.string("settings_sample_text"), settings: settings)
                        .padding(.vertical, 4)
                        .accessibilityIdentifier("settings_sample_text")
                }
            }
        }
        .navigationTitle("settings_display")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.observe() }
    }
}

/// 段階を選ぶスライダー（題名・今の段階の名前・スライダー）。読み込み中（selected が nil）は押せない。
private struct StepSlider<Level: Equatable>: View {
    let title: LocalizedStringKey
    let levels: [Level]
    let selected: Level?
    let label: KeyPath<Level, LocalizedStringKey>
    let onSelect: (Level) -> Void

    var body: some View {
        let index = selected.flatMap { levels.firstIndex(of: $0) } ?? 0
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(title)
                Spacer()
                if let selected {
                    Text(selected[keyPath: label]).foregroundStyle(.secondary)
                }
            }
            Slider(
                value: Binding(
                    get: { Double(index) },
                    set: { value in
                        let newIndex = min(max(Int(value.rounded()), 0), levels.count - 1)
                        onSelect(levels[newIndex])
                    }),
                in: 0...Double(levels.count - 1),
                step: 1
            ) {
                Text(title)
            }
            .disabled(selected == nil)
            // 読み上げでは段階の名前（例: 「中」）を伝える
            .accessibilityValue(selected.map { Text($0[keyPath: label]) } ?? Text(""))
        }
        .padding(.vertical, 4)
    }
}

/// サンプルの文章。編集画面と同じ見た目（MemoTextAttributes）で、書き換えはできない。
private struct MemoSampleText: UIViewRepresentable {
    let text: String
    let settings: EditorSettings

    func makeUIView(context: Context) -> UITextView {
        // 編集画面と同じく TextKit 1 にして、行の高さの計算をそろえる
        let view = UITextView(usingTextLayoutManager: false)
        view.isEditable = false
        view.isSelectable = false
        view.isScrollEnabled = false
        view.backgroundColor = .clear
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: UITextView, context: Context) {
        view.attributedText = NSAttributedString(
            string: text, attributes: MemoTextAttributes.attributes(for: TextFormat(), settings: settings))
        view.accessibilityLabel = text
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: UITextView, context: Context) -> CGSize? {
        let width = proposal.width ?? UIView.layoutFittingExpandedSize.width
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: height)
    }
}

extension FontSizeLevel {
    /// 段階の名前（小 / 中 / 大 / 特大）。
    var labelKey: LocalizedStringKey {
        switch self {
        case .small: "font_size_small"
        case .medium: "font_size_medium"
        case .large: "font_size_large"
        case .extraLarge: "font_size_extra_large"
        }
    }
}

extension LineSpacingLevel {
    /// 段階の名前（狭い / 標準 / 広い / とても広い）。
    var labelKey: LocalizedStringKey {
        switch self {
        case .narrow: "line_spacing_narrow"
        case .normal: "line_spacing_normal"
        case .wide: "line_spacing_wide"
        case .extraWide: "line_spacing_extra_wide"
        }
    }
}
