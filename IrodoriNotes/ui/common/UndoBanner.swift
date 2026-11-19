import SwiftUI

/// 「〇〇しました［元に戻す］」のお知らせ（Android の Snackbar にあたる。iOS には同じ部品がないので作った）。
struct UndoItem: Identifiable {
    let id = UUID()
    let message: String
    /// nil なら「元に戻す」ボタンを出さない（お知らせだけ）
    let undo: (() -> Void)?
}

extension View {
    /// 画面の下（下タブの上）に「元に戻す」のお知らせを出す。3秒たつと消える（Android の Snackbar の LENGTH_LONG とほぼ同じ）。
    func undoBanner(_ item: Binding<UndoItem?>) -> some View {
        safeAreaInset(edge: .bottom) {
            if let current = item.wrappedValue {
                UndoBanner(item: current) { item.wrappedValue = nil }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .task(id: current.id) {
                        try? await Task.sleep(for: .seconds(3))
                        if item.wrappedValue?.id == current.id { item.wrappedValue = nil }
                    }
            }
        }
        .animation(.default, value: item.wrappedValue?.id)
    }
}

private struct UndoBanner: View {
    let item: UndoItem
    let dismiss: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Text(item.message)
                .foregroundStyle(Color("SnackbarText"))
                .frame(maxWidth: .infinity, alignment: .leading)
            if let undo = item.undo {
                Button {
                    undo()
                    dismiss()
                } label: {
                    Text("action_undo").fontWeight(.semibold)
                }
                .foregroundStyle(Color("SnackbarAction"))
                .accessibilityIdentifier("undo_button")
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color("SnackbarBackground"), in: RoundedRectangle(cornerRadius: 8))
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("undo_banner")
    }
}
