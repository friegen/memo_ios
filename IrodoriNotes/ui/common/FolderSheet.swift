import SwiftUI

/// フォルダの作成・編集のシート（名前と色）。Android 版の FolderDialog にあたる（iOS のアラートには色の丸を置けないため、下から出るシートにした）。
/// 開いたらキーボードを出す。名前が空のあいだは決定ボタンを押せない。
struct FolderSheet: View {
    enum Mode: Identifiable {
        case create
        case edit(Folder)

        var id: String {
            switch self {
            case .create: "create"
            case .edit(let folder): "edit-\(folder.id)"
            }
        }
    }

    let mode: Mode
    let onSubmit: (_ name: String, _ color: FolderColor) -> Void

    @State private var name: String
    @State private var color: FolderColor
    @FocusState private var isNameFocused: Bool
    @Environment(\.dismiss) private var dismiss

    init(mode: Mode, onSubmit: @escaping (_ name: String, _ color: FolderColor) -> Void) {
        self.mode = mode
        self.onSubmit = onSubmit
        switch mode {
        case .create:
            _name = State(initialValue: "")
            _color = State(initialValue: .default)
        case .edit(let folder):
            _name = State(initialValue: folder.name)
            _color = State(initialValue: folder.color)
        }
    }

    private var isEdit: Bool {
        if case .edit = mode { return true }
        return false
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .trailing, spacing: 4) {
                    TextField("folder_name_hint", text: $name)
                        .textFieldStyle(.roundedBorder)
                        .focused($isNameFocused)
                        .submitLabel(.done)
                        .onSubmit(submit)
                        .accessibilityIdentifier("folder_name_field")
                        .onChange(of: name) { _, newValue in
                            // 50文字まで（Android の入力欄の上限と同じ）
                            if newValue.count > FolderPolicy.maxNameLength {
                                name = String(newValue.prefix(FolderPolicy.maxNameLength))
                            }
                        }
                    Text(verbatim: "\(name.count)/\(FolderPolicy.maxNameLength)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                // 色の丸（既定＋9色）を5個×2段
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 5), spacing: 12) {
                    ForEach(FolderColor.allCases, id: \.self) { option in
                        colorChip(option)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding()
            .navigationTitle(isEdit ? "folder_dialog_edit_title" : "folder_dialog_create_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action_cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEdit ? "action_save" : "action_create", action: submit)
                        .disabled(name.isBlank)
                        .accessibilityIdentifier("folder_submit_button")
                }
            }
        }
        .presentationDetents([.medium, .large])
        .onAppear { isNameFocused = true }
    }

    private func submit() {
        guard !name.isBlank else { return }
        onSubmit(name, color)
        dismiss()
    }

    private func colorChip(_ option: FolderColor) -> some View {
        let selected = option == color
        return Button {
            color = option
        } label: {
            Circle()
                .fill(option.uiColor.map { Color($0) } ?? Color(.systemBackground))
                .overlay(Circle().strokeBorder(Color(.separator), lineWidth: 1))
                .frame(width: 36, height: 36)
                .padding(4)
                .overlay {
                    if selected { Circle().strokeBorder(Color.accentColor, lineWidth: 2.5) }
                }
                .frame(width: 48, height: 48)
        }
        .accessibilityLabel(Text(LocalizedStringKey(option.nameKey)))
        .accessibilityAddTraits(selected ? .isSelected : [])
        .accessibilityIdentifier("folder_color_\(option.rawValue)")
    }
}
