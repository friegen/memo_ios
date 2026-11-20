import SwiftUI

extension View {
    /// ナビゲーションバーの中央にタイトルとサブタイトル（編集画面の文字数・行数、フォルダの中の上の階層など）。
    /// iOS 26 からは標準のサブタイトル（`.navigationSubtitle`）を使う（iOS 26.0 では自前の中央の表示 `.principal` が出ないため）。
    /// iOS 18〜25 は自前で2行に並べる。サブタイトルが空なら1行。
    func titleAndSubtitle(_ title: String, subtitle: String) -> some View {
        modifier(TitleAndSubtitle(title: title, subtitle: subtitle))
    }
}

private struct TitleAndSubtitle: ViewModifier {
    let title: String
    let subtitle: String

    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content
                .navigationTitle(title)
                .navigationSubtitle(subtitle)
                .navigationBarTitleDisplayMode(.inline)
        } else {
            content
                .navigationTitle(title)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .principal) {
                        VStack(spacing: 0) {
                            Text(title).font(.headline)
                            if !subtitle.isEmpty {
                                Text(subtitle).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .lineLimit(1)
                    }
                }
        }
    }
}
