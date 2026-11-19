import SwiftUI

/// 並び替えメニューの選択肢1つ。
struct SortOption<Value: Hashable>: Identifiable {
    let label: LocalizedStringKey
    let value: Value
    var id: Value { value }
}

/// メモ一覧（メモタブ・フォルダ内のメモ）の並び替えの選択肢（Android 版と同じ6つ）。
let memoSortOptions: [SortOption<MemoSort>] = [
    SortOption(label: "sort_updated_desc", value: MemoSort(key: .updatedAt, ascending: false)),
    SortOption(label: "sort_updated_asc", value: MemoSort(key: .updatedAt, ascending: true)),
    SortOption(label: "sort_created_desc", value: MemoSort(key: .createdAt, ascending: false)),
    SortOption(label: "sort_created_asc", value: MemoSort(key: .createdAt, ascending: true)),
    SortOption(label: "sort_chars_desc", value: MemoSort(key: .charCount, ascending: false)),
    SortOption(label: "sort_chars_asc", value: MemoSort(key: .charCount, ascending: true)),
]

/// ナビゲーションバーの並び替えボタン。押すとメニューが出て、選んでいるものにチェックが付く。
/// 「項目＋向き」を1つの選択肢にまとめ（例: 更新日が新しい順）、1回のタップで決まるようにしている（Android と同じ）。
struct SortMenu<Value: Hashable>: View {
    let options: [SortOption<Value>]
    let current: Value
    let onSelect: (Value) -> Void

    var body: some View {
        Menu {
            Section {
                ForEach(options) { option in
                    Button {
                        onSelect(option.value)
                    } label: {
                        if option.value == current {
                            Label(option.label, systemImage: "checkmark") // 選んでいるもの
                        } else {
                            Text(option.label)
                        }
                    }
                }
            } header: {
                Text("sort_title") // メニューの見出し（Android のダイアログの題名にあたる）
            }
        } label: {
            Label("action_sort", systemImage: "arrow.up.arrow.down")
        }
        .accessibilityIdentifier("sort_button")
    }
}
