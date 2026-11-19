import Foundation
import Testing
import UIKit
@testable import IrodoriNotes

/// メイン画面の ViewModel（テーマ）。
struct MainViewModelTests {

    @Test func startsWithSavedThemeMode() throws {
        let (container, _, _) = try makeTestContainer()
        container.settingsRepository.setThemeMode(.dark)

        let viewModel = container.makeMainViewModel()

        #expect(viewModel.uiState.themeMode == .dark) // 最初の画面から保存しているテーマ
    }

    @Test func followsThemeModeChanges() async throws {
        let (container, _, _) = try makeTestContainer()
        let viewModel = container.makeMainViewModel()
        let task = Task { await viewModel.observe() }
        defer { task.cancel() }

        container.settingsRepository.setThemeMode(.light)

        try await waitUntil { viewModel.uiState.themeMode == .light }
    }

    @Test func themeModeMapsToInterfaceStyle() {
        #expect(ThemeMode.system.userInterfaceStyle == .unspecified)
        #expect(ThemeMode.light.userInterfaceStyle == .light)
        #expect(ThemeMode.dark.userInterfaceStyle == .dark)
    }
}

/// 条件が満たされるまで少しずつ待つ（最大 `timeout` 秒）。ViewModel が非同期で状態を変えるのを待つのに使う。
func waitUntil(timeout: Double = 3, _ condition: () -> Bool) async throws {
    let deadline = Date().addingTimeInterval(timeout)
    while !condition() {
        if Date() > deadline {
            Issue.record("時間内に条件が満たされなかった")
            return
        }
        try await Task.sleep(for: .milliseconds(20))
    }
}
