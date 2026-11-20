import SwiftUI

/// フォルダの中（仮）。タイトルにフォルダ名だけ出す。中のフォルダとメモの一覧はステップ7で作る。
struct FolderDetailScreen: View {
    let folderId: Int64
    private let observeFolder: ObserveFolderUseCase
    @State private var folder: Folder?

    init(container: AppContainer, folderId: Int64) {
        self.folderId = folderId
        observeFolder = container.makeObserveFolderUseCase()
    }

    var body: some View {
        Color.clear
            .navigationTitle(folder?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("folder_detail")
            .task {
                do {
                    for try await folder in observeFolder(folderId: folderId) { self.folder = folder }
                } catch {
                    AppLog.error("フォルダを読めなかった: \(error)")
                }
            }
    }
}
