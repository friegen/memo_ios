import SwiftUI

/// メモの移動先のフォルダを選ぶシート（Android 版の MoveTargetDialog にあたる）。全フォルダを階層どおり（字下げ）に並べる。
/// 今いるフォルダも階層が分かるように表示するが、選べない（薄く表示）。アイコンはフォルダの色で塗った丸。
struct MoveTargetSheet: View {
    let targets: [FolderTreeEntry]
    let currentFolderId: Int64
    let onSelect: (FolderTreeEntry) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(targets) { target in
                let isCurrent = target.id == currentFolderId
                Button {
                    onSelect(target)
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        ColorBadge(color: target.color)
                        Text(target.name)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                    }
                    .padding(.leading, CGFloat(target.depth - 1) * 20)
                    .opacity(isCurrent ? 0.38 : 1)
                }
                .disabled(isCurrent)
                .accessibilityIdentifier("move_target")
            }
            .listStyle(.plain)
            .navigationTitle("move_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
    }
}

/// フォルダの色で塗った丸に、フォルダのアイコン（移動先の一覧とゴミ箱で共通。Android 版の ColorBadge にあたる）。
/// 色なしのフォルダは画面の背景の色＋枠線。
struct ColorBadge: View {
    let color: FolderColor
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        let background = color.uiColor
        let iconColor: Color = background.map { uiColor in
            let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
            return Color(FolderColors.contentColor(on: uiColor.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))))
        } ?? .accentColor
        Circle()
            .fill(background.map { Color($0) } ?? Color(.systemBackground))
            .overlay(Circle().strokeBorder(Color(.separator), lineWidth: background == nil ? 1 : 0))
            .frame(width: 32, height: 32)
            .overlay {
                Image(systemName: "folder.fill")
                    .font(.footnote)
                    .foregroundStyle(iconColor)
            }
            .accessibilityHidden(true)
    }
}
