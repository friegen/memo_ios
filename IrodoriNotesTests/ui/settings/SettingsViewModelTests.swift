import Foundation
import Testing
@testable import IrodoriNotes

/// 設定のトップ・「表示」・「データ」・ライセンスの ViewModel（Android 版の SettingsViewModelTest などと同じ内容）。
struct SettingsViewModelTests {

    @Test func theme_showsSavedValueAndSavesSelection() async throws {
        let (container, defaults, _) = try makeTestContainer()
        container.settingsRepository.setThemeMode(.dark)
        let viewModel = container.makeSettingsViewModel()
        #expect(viewModel.uiState.themeMode == nil) // 読み込み中はどれも選ばれていない
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }

        try await waitUntil { viewModel.uiState.themeMode == .dark }

        viewModel.onThemeModeSelected(.light)
        #expect(defaults.string(forKey: SettingsKeys.themeMode) == "LIGHT")
        try await waitUntil { viewModel.uiState.themeMode == .light }
    }

    @Test func display_showsDefaultsAndSavesLevels() async throws {
        let (container, defaults, _) = try makeTestContainer()
        let viewModel = container.makeDisplaySettingsViewModel()
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }

        try await waitUntil { viewModel.uiState.settings == EditorSettings(fontSize: .medium, lineSpacing: .normal) }

        viewModel.onFontSizeSelected(.extraLarge)
        viewModel.onLineSpacingSelected(.narrow)
        #expect(defaults.string(forKey: SettingsKeys.fontSize) == "EXTRA_LARGE")
        #expect(defaults.string(forKey: SettingsKeys.lineSpacing) == "NARROW")
        try await waitUntil { viewModel.uiState.settings == EditorSettings(fontSize: .extraLarge, lineSpacing: .narrow) }
    }

    @Test func data_showsSizeAfterLoading() async throws {
        let root = FileManager.default.temporaryDirectory.appendingPathComponent("DataSettings-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        try Data(repeating: 1, count: 2048).write(to: root.appendingPathComponent("memo.sqlite"))
        let viewModel = DataSettingsViewModel(getDataUsage: GetDataUsageUseCase(storageRepository: StorageRepository(targets: [root])))
        #expect(viewModel.uiState.dataBytes == nil)

        await viewModel.load()

        #expect(viewModel.uiState.dataBytes == 2048)
    }

    @Test func licenses_listsLibraries() async throws {
        let viewModel = try makeTestContainer().container.makeLicensesViewModel()
        #expect(viewModel.uiState.isLoading)

        await viewModel.load()

        #expect(!viewModel.uiState.isLoading)
        #expect(viewModel.uiState.libraries.contains { $0.id == "grdb.swift" })
    }
}
