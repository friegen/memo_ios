import Foundation
import os

/// Repository・UseCase・ViewModel を作って渡す入れ物（Android 版の Koin のモジュールにあたる）。
///
/// - Repository は1つだけ作って使い回す（Koin の single）
/// - UseCase・ViewModel は `makeXxx()` で呼ぶたびに作る（Koin の factory / viewModel）
final class AppContainer {
    let database: AppDatabase
    let clock: AppClock

    let memoRepository: MemoRepository
    let folderRepository: FolderRepository
    let trashRepository: TrashRepository
    let settingsRepository: SettingsRepository

    init(database: AppDatabase, defaults: UserDefaults = .standard, clock: AppClock = AppClock()) {
        self.database = database
        self.clock = clock
        memoRepository = MemoRepository(database: database)
        folderRepository = FolderRepository(database: database)
        trashRepository = TrashRepository(database: database)
        settingsRepository = SettingsRepository(defaults: defaults)
    }

    /// アプリで使う入れ物（ファイルの DB・ふだんの UserDefaults）。
    static func makeDefault() -> AppContainer {
        #if DEBUG
        // UI テストのときは、メモリ上の DB と別の保存先の設定を使う（UITestSupport.swift）
        if let container = UITestSupport.makeContainerIfRequested() { return container }
        #endif
        do {
            return AppContainer(database: try AppDatabase.makeDefault())
        } catch {
            // DB を開けないとアプリが動かないので止める（原因はログに残る）
            fatalError("DB を開けませんでした: \(error)")
        }
    }

    // MARK: UseCase

    func makePurgeExpiredTrashUseCase() -> PurgeExpiredTrashUseCase {
        PurgeExpiredTrashUseCase(trashRepository: trashRepository, clock: clock)
    }

    func makeGetThemeModeUseCase() -> GetThemeModeUseCase {
        GetThemeModeUseCase(settingsRepository: settingsRepository)
    }

    func makeObserveThemeModeUseCase() -> ObserveThemeModeUseCase {
        ObserveThemeModeUseCase(settingsRepository: settingsRepository)
    }

    func makeObserveMemoTabMemosUseCase() -> ObserveMemoTabMemosUseCase {
        ObserveMemoTabMemosUseCase(memoRepository: memoRepository, settingsRepository: settingsRepository)
    }

    func makeSetMemoTabSortUseCase() -> SetMemoTabSortUseCase {
        SetMemoTabSortUseCase(settingsRepository: settingsRepository)
    }

    func makeMoveMemoToTrashUseCase() -> MoveMemoToTrashUseCase {
        MoveMemoToTrashUseCase(memoRepository: memoRepository, clock: clock)
    }

    func makeRestoreMemoUseCase() -> RestoreMemoUseCase {
        RestoreMemoUseCase(trashRepository: trashRepository, clock: clock)
    }

    func makeSetMemoPinnedUseCase() -> SetMemoPinnedUseCase {
        SetMemoPinnedUseCase(memoRepository: memoRepository)
    }

    // MARK: ViewModel

    func makeMainViewModel() -> MainViewModel {
        MainViewModel(getThemeMode: makeGetThemeModeUseCase(), observeThemeMode: makeObserveThemeModeUseCase())
    }

    func makeMemoListViewModel() -> MemoListViewModel {
        MemoListViewModel(
            observeMemoTabMemos: makeObserveMemoTabMemosUseCase(),
            setMemoTabSort: makeSetMemoTabSortUseCase(),
            moveMemoToTrash: makeMoveMemoToTrashUseCase(),
            restoreMemo: makeRestoreMemoUseCase(),
            setMemoPinned: makeSetMemoPinnedUseCase())
    }
}

/// アプリのログ（Android の Log にあたる。Xcode のコンソールに出る）。
nonisolated enum AppLog {
    private static let logger = Logger(subsystem: "xyz.friegen.memo", category: "app")

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
