import SwiftUI

/// 最初の画面（仮）。ステップ2で下タブ（メモ / フォルダ / 設定）に置き換える。
struct RootView: View {
    var body: some View {
        Text("app_name")
            .font(.title)
            .accessibilityIdentifier("root_title")
    }
}

#Preview {
    RootView()
}
