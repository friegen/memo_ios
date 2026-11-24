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
    let storageRepository: StorageRepository
    let licenseRepository: LicenseRepository

    /// アプリ全体のお知らせ（「ゴミ箱に移動しました［元に戻す］」など）
    let messageCenter = MessageCenter()
    /// ロックを外している状態（アプリで1つ）
    let lockSession = LockSession()
    /// 端末の認証（Face ID / Touch ID・パスコード）
    let deviceAuthenticator: DeviceAuthenticator
    /// メモの出力（PDF・画像・テキスト・HTML のファイルを作る）
    let memoExporter = MemoExporter()

    /// - Parameter makeAuthenticator: UI テストでは認証の結果を決めて返すものに差し替える
    init(
        database: AppDatabase, defaults: UserDefaults = .standard, clock: AppClock = AppClock(),
        makeAuthenticator: (LockSession) -> DeviceAuthenticator = { DeviceAuthenticator(lockSession: $0) }
    ) {
        self.database = database
        self.clock = clock
        memoRepository = MemoRepository(database: database)
        folderRepository = FolderRepository(database: database)
        trashRepository = TrashRepository(database: database)
        settingsRepository = SettingsRepository(defaults: defaults)
        storageRepository = StorageRepository()
        licenseRepository = LicenseRepository()
        deviceAuthenticator = makeAuthenticator(lockSession)
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

    func makeGetMemoUseCase() -> GetMemoUseCase {
        GetMemoUseCase(memoRepository: memoRepository)
    }

    func makeSaveMemoUseCase() -> SaveMemoUseCase {
        SaveMemoUseCase(memoRepository: memoRepository, clock: clock)
    }

    func makeRevertMemoUseCase() -> RevertMemoUseCase {
        RevertMemoUseCase(memoRepository: memoRepository)
    }

    func makeDiscardMemoUseCase() -> DiscardMemoUseCase {
        DiscardMemoUseCase(trashRepository: trashRepository)
    }

    func makeObserveEditorSettingsUseCase() -> ObserveEditorSettingsUseCase {
        ObserveEditorSettingsUseCase(settingsRepository: settingsRepository)
    }

    func makeObserveRootFoldersUseCase() -> ObserveRootFoldersUseCase {
        ObserveRootFoldersUseCase(folderRepository: folderRepository, settingsRepository: settingsRepository)
    }

    func makeSetFolderListSortUseCase() -> SetFolderListSortUseCase {
        SetFolderListSortUseCase(settingsRepository: settingsRepository)
    }

    func makeCreateFolderUseCase() -> CreateFolderUseCase {
        CreateFolderUseCase(folderRepository: folderRepository, clock: clock)
    }

    func makeUpdateFolderUseCase() -> UpdateFolderUseCase {
        UpdateFolderUseCase(folderRepository: folderRepository)
    }

    func makeCountFolderContentsUseCase() -> CountFolderContentsUseCase {
        CountFolderContentsUseCase(folderRepository: folderRepository)
    }

    func makeMoveFolderToTrashUseCase() -> MoveFolderToTrashUseCase {
        MoveFolderToTrashUseCase(folderRepository: folderRepository, clock: clock)
    }

    func makeRestoreFolderUseCase() -> RestoreFolderUseCase {
        RestoreFolderUseCase(trashRepository: trashRepository, clock: clock)
    }

    func makeSetFolderPinnedUseCase() -> SetFolderPinnedUseCase {
        SetFolderPinnedUseCase(folderRepository: folderRepository)
    }

    func makeObserveFolderUseCase() -> ObserveFolderUseCase {
        ObserveFolderUseCase(folderRepository: folderRepository)
    }

    func makeObserveChildFoldersUseCase() -> ObserveChildFoldersUseCase {
        ObserveChildFoldersUseCase(folderRepository: folderRepository, settingsRepository: settingsRepository)
    }

    func makeObserveFolderMemosUseCase() -> ObserveFolderMemosUseCase {
        ObserveFolderMemosUseCase(memoRepository: memoRepository, settingsRepository: settingsRepository)
    }

    func makeSetFolderMemoSortUseCase() -> SetFolderMemoSortUseCase {
        SetFolderMemoSortUseCase(settingsRepository: settingsRepository)
    }

    func makeGetFolderPathUseCase() -> GetFolderPathUseCase {
        GetFolderPathUseCase(folderRepository: folderRepository)
    }

    func makeGetFolderTreeUseCase() -> GetFolderTreeUseCase {
        GetFolderTreeUseCase(folderRepository: folderRepository)
    }

    func makeMoveMemoToFolderUseCase() -> MoveMemoToFolderUseCase {
        MoveMemoToFolderUseCase(memoRepository: memoRepository, clock: clock)
    }

    func makeSetThemeModeUseCase() -> SetThemeModeUseCase {
        SetThemeModeUseCase(settingsRepository: settingsRepository)
    }

    func makeSetFontSizeUseCase() -> SetFontSizeUseCase {
        SetFontSizeUseCase(settingsRepository: settingsRepository)
    }

    func makeSetLineSpacingUseCase() -> SetLineSpacingUseCase {
        SetLineSpacingUseCase(settingsRepository: settingsRepository)
    }

    func makeGetDataUsageUseCase() -> GetDataUsageUseCase {
        GetDataUsageUseCase(storageRepository: storageRepository)
    }

    func makeGetOssLibrariesUseCase() -> GetOssLibrariesUseCase {
        GetOssLibrariesUseCase(licenseRepository: licenseRepository)
    }

    func makeObserveTrashItemsUseCase() -> ObserveTrashItemsUseCase {
        ObserveTrashItemsUseCase(trashRepository: trashRepository)
    }

    func makeDeleteMemoPermanentlyUseCase() -> DeleteMemoPermanentlyUseCase {
        DeleteMemoPermanentlyUseCase(trashRepository: trashRepository)
    }

    func makeDeleteFolderPermanentlyUseCase() -> DeleteFolderPermanentlyUseCase {
        DeleteFolderPermanentlyUseCase(trashRepository: trashRepository)
    }

    func makeCountTrashedFolderContentsUseCase() -> CountTrashedFolderContentsUseCase {
        CountTrashedFolderContentsUseCase(trashRepository: trashRepository)
    }

    func makeEmptyTrashUseCase() -> EmptyTrashUseCase {
        EmptyTrashUseCase(trashRepository: trashRepository)
    }

    func makeSetMemoLockedUseCase() -> SetMemoLockedUseCase {
        SetMemoLockedUseCase(memoRepository: memoRepository)
    }

    func makeSetFolderLockedUseCase() -> SetFolderLockedUseCase {
        SetFolderLockedUseCase(folderRepository: folderRepository)
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
            setMemoPinned: makeSetMemoPinnedUseCase(),
            setMemoLocked: makeSetMemoLockedUseCase())
    }

    func makeFolderListViewModel() -> FolderListViewModel {
        FolderListViewModel(
            observeRootFolders: makeObserveRootFoldersUseCase(),
            setFolderListSort: makeSetFolderListSortUseCase(),
            createFolder: makeCreateFolderUseCase(),
            updateFolder: makeUpdateFolderUseCase(),
            countFolderContents: makeCountFolderContentsUseCase(),
            moveFolderToTrash: makeMoveFolderToTrashUseCase(),
            restoreFolder: makeRestoreFolderUseCase(),
            setFolderPinned: makeSetFolderPinnedUseCase(),
            setFolderLocked: makeSetFolderLockedUseCase())
    }

    func makeFolderDetailViewModel(folderId: Int64) -> FolderDetailViewModel {
        FolderDetailViewModel(
            folderId: folderId,
            observeFolder: makeObserveFolderUseCase(),
            observeChildFolders: makeObserveChildFoldersUseCase(),
            observeFolderMemos: makeObserveFolderMemosUseCase(),
            getFolderPath: makeGetFolderPathUseCase(),
            getFolderTree: makeGetFolderTreeUseCase(),
            setFolderListSort: makeSetFolderListSortUseCase(),
            setFolderMemoSort: makeSetFolderMemoSortUseCase(),
            createFolder: makeCreateFolderUseCase(),
            updateFolder: makeUpdateFolderUseCase(),
            countFolderContents: makeCountFolderContentsUseCase(),
            moveFolderToTrash: makeMoveFolderToTrashUseCase(),
            restoreFolder: makeRestoreFolderUseCase(),
            moveMemoToTrash: makeMoveMemoToTrashUseCase(),
            restoreMemo: makeRestoreMemoUseCase(),
            moveMemoToFolder: makeMoveMemoToFolderUseCase(),
            setMemoPinned: makeSetMemoPinnedUseCase(),
            setFolderPinned: makeSetFolderPinnedUseCase(),
            setMemoLocked: makeSetMemoLockedUseCase(),
            setFolderLocked: makeSetFolderLockedUseCase())
    }

    func makeMemoEditViewModel(memoId: Int64?, folderId: Int64?) -> MemoEditViewModel {
        MemoEditViewModel(
            memoId: memoId,
            folderId: folderId,
            getMemo: makeGetMemoUseCase(),
            saveMemo: makeSaveMemoUseCase(),
            moveMemoToTrash: makeMoveMemoToTrashUseCase(),
            revertMemo: makeRevertMemoUseCase(),
            discardMemo: makeDiscardMemoUseCase(),
            observeEditorSettings: makeObserveEditorSettingsUseCase(),
            getFolderPath: makeGetFolderPathUseCase())
    }

    func makeSettingsViewModel() -> SettingsViewModel {
        SettingsViewModel(observeThemeMode: makeObserveThemeModeUseCase(), setThemeMode: makeSetThemeModeUseCase())
    }

    func makeDisplaySettingsViewModel() -> DisplaySettingsViewModel {
        DisplaySettingsViewModel(
            observeEditorSettings: makeObserveEditorSettingsUseCase(),
            setFontSize: makeSetFontSizeUseCase(),
            setLineSpacing: makeSetLineSpacingUseCase())
    }

    func makeDataSettingsViewModel() -> DataSettingsViewModel {
        DataSettingsViewModel(getDataUsage: makeGetDataUsageUseCase())
    }

    func makeLicensesViewModel() -> LicensesViewModel {
        LicensesViewModel(getOssLibraries: makeGetOssLibrariesUseCase())
    }

    func makeTrashViewModel() -> TrashViewModel {
        TrashViewModel(
            observeTrashItems: makeObserveTrashItemsUseCase(),
            restoreMemo: makeRestoreMemoUseCase(),
            restoreFolder: makeRestoreFolderUseCase(),
            deleteMemoPermanently: makeDeleteMemoPermanentlyUseCase(),
            deleteFolderPermanently: makeDeleteFolderPermanentlyUseCase(),
            countTrashedFolderContents: makeCountTrashedFolderContentsUseCase(),
            emptyTrash: makeEmptyTrashUseCase())
    }
}

/// アプリのログ（Android の Log にあたる。Xcode のコンソールに出る）。
nonisolated enum AppLog {
    private static let logger = Logger(subsystem: "xyz.friegen.memo", category: "app")

    static func error(_ message: String) {
        logger.error("\(message, privacy: .public)")
    }
}
