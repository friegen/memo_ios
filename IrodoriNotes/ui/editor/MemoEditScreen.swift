import SwiftUI

/// メモの編集画面（仮）。中身はステップ4で作る。
/// 下タブは隠す（Android 版では別の Activity で、下タブがない）。
struct MemoEditScreen: View {
    let memoId: Int64?
    let folderId: Int64?

    var body: some View {
        Color.clear
            .accessibilityIdentifier("memo_editor")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .tabBar)
    }
}
