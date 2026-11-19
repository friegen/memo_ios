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

    // MARK: ViewModel

    func makeMainViewModel() -> MainViewModel {
        MainViewModel(getThemeMode: makeGetThemeModeUseCase(), observeThemeMode: makeObserveThemeModeUseCase())
    }
}

/// アプリのログ（Android の Log にあたる。Xcode のコンソールに出る）。
nonisolated enum AppLog {
    static let app = Logger(subsystem: "xyz.friegen.memo", category: "app")
}
