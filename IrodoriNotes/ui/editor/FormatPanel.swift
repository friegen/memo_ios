import SwiftUI

/// 書式パネル（メモ編集画面の下、キーボードの上）。Android 版の view_format_panel にあたる。
/// 1段目: 太字・斜体・下線と閉じる / 2段目: 文字色（既定＋10色。横にスクロール）
/// ボタンを押しても入力欄の選択範囲は外れない（SwiftUI のボタンはキーボードの入力先を奪わないため）。
struct FormatPanel: View {
    let state: FormatPanelState
    let onToggle: (MemoTextStyle) -> Void
    let onColor: (String?) -> Void
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                styleButton(.bold, label: Text(verbatim: "B").bold(), name: "format_bold")
                styleButton(.italic, label: Text(verbatim: "I").italic(), name: "format_italic")
                styleButton(.underline, label: Text(verbatim: "U").underline(), name: "format_underline")
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.body.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                }
                .accessibilityLabel(Text("format_close"))
                .accessibilityIdentifier("format_close_button")
            }
            .padding(.horizontal, 8)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    colorChip(nil, color: Color.primary, name: "color_default", selected: state.selectedColor == .default)
                    ForEach(MemoTextColor.allCases, id: \.self) { color in
                        colorChip(color.rawValue, color: Color(color.assetName), name: LocalizedStringKey(color.nameKey),
                                  selected: state.selectedColor == .color(color.rawValue))
                    }
                }
                .padding(.horizontal, 8)
            }
        }
        .padding(.vertical, 6)
        .background(Color(.secondarySystemBackground))
        .overlay(alignment: .top) { Divider() }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("format_panel")
    }

    private func styleButton(_ style: MemoTextStyle, label: Text, name: LocalizedStringKey) -> some View {
        let isOn = state.format.has(style)
        return Button {
            onToggle(style)
        } label: {
            label
                .font(.title3)
                .frame(width: 44, height: 44)
                .foregroundStyle(isOn ? Color.accentColor : Color.primary)
                .background(isOn ? Color.accentColor.opacity(0.18) : Color.clear, in: RoundedRectangle(cornerRadius: 10))
        }
        .accessibilityLabel(Text(name))
        .accessibilityAddTraits(isOn ? .isSelected : [])
        .accessibilityIdentifier("format_\(style)")
    }

    private func colorChip(_ key: String?, color: Color, name: LocalizedStringKey, selected: Bool) -> some View {
        Button {
            onColor(key)
        } label: {
            Circle()
                .fill(color)
                // 背景と同じ明るさの色でも境目が見えるよう細い線を付ける
                .overlay(Circle().strokeBorder(Color(.separator), lineWidth: 1))
                .frame(width: 28, height: 28)
                .padding(4)
                .overlay {
                    if selected {
                        Circle().strokeBorder(Color.accentColor, lineWidth: 2.5)
                    }
                }
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(Text(name))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("color_\(key ?? "default")")
    }
}
