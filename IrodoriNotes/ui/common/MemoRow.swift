import SwiftUI

/// メモ一覧の1行（メモタブ・フォルダ内のメモで共通）: （ピン・ロックのアイコン）1行目 / 作成日・更新日 / 文字数。
struct MemoRow: View {
    let memo: MemoSummary

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    if memo.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("pin_icon_description"))
                    }
                    if memo.isLocked {
                        // ロックしたメモも1行目は表示する（何のメモか分かるように。本文は開くときに認証する）
                        Image(systemName: "lock.fill")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(Text("lock_icon_description"))
                    }
                    Text(memo.firstLine.isEmpty ? L10n.string("memo_no_text") : memo.firstLine)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                }
                Text(DateTimeText.createdAndUpdated(createdAt: memo.createdAt, updatedAt: memo.isUpdated ? memo.updatedAt : nil))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            // 3桁ごとの区切り（例: 12,345）。区切り文字は端末の言語に合わせる
            Text(memo.charCount.formatted())
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .frame(minWidth: 36)
                .background(Color(.tertiarySystemFill), in: Capsule())
                .accessibilityLabel(L10n.format("memo_char_count_description", memo.charCount))
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
