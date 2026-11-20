import SwiftUI

/// フォルダ一覧の1行（フォルダタブ・フォルダの中で共通）: フォルダのアイコン・（ピン・ロック）名前 / 作成日・更新日 / 件数。
/// 行全体をフォルダの色で塗り、文字色は背景から白／黒を選ぶ（行の背景は呼び出し側で `.listRowBackground(folder.color.rowBackground)`）。
struct FolderRow: View {
    let folder: Folder
    @Environment(\.colorScheme) private var colorScheme

    /// 文字・アイコンの色。色なしのフォルダはふつうの文字色。
    private var contentColor: Color {
        guard let background = folder.color.uiColor else { return .primary }
        let style: UIUserInterfaceStyle = colorScheme == .dark ? .dark : .light
        let resolved = background.resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
        return Color(FolderColors.contentColor(on: resolved))
    }

    var body: some View {
        let content = contentColor
        let secondary = folder.color == .default ? Color.secondary : content.opacity(0.75)
        HStack(spacing: 12) {
            Image(systemName: "folder.fill")
                .font(.title3)
                .foregroundStyle(folder.color == .default ? Color.accentColor : content)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if folder.isPinned {
                        Image(systemName: "pin.fill").font(.footnote).foregroundStyle(secondary)
                            .accessibilityLabel(Text("pin_icon_description"))
                    }
                    if folder.isLocked {
                        Image(systemName: "lock.fill").font(.footnote).foregroundStyle(secondary)
                            .accessibilityLabel(Text("lock_icon_description"))
                    }
                    Text(folder.name)
                        .font(.body)
                        .foregroundStyle(content)
                        .lineLimit(1)
                }
                Text(DateTimeText.createdAndUpdated(createdAt: folder.createdAt, updatedAt: folder.isUpdated ? folder.updatedAt : nil))
                    .font(.caption)
                    .foregroundStyle(secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(folder.itemCount.formatted())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minWidth: 36)
                .background(folder.color == .default ? Color(.tertiarySystemFill) : content.opacity(0.12), in: Capsule())
                .accessibilityLabel(L10n.format("folder_item_count_description", folder.itemCount))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

extension FolderColor {
    /// 一覧の行の背景。色なしは画面の背景のまま。
    var rowBackground: Color? {
        uiColor.map { Color($0) }
    }
}
