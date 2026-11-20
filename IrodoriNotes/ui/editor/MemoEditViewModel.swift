import Foundation
import Observation

/// メモ編集画面の状態。
struct MemoEditUiState: Equatable {
    var isLoading = true
    var charCount = 0
    var lineCount = 0
    /// 文字を選んでいる間だけ、選んだ範囲の文字数（改行は数えない）。選んでいなければ nil
    var selectedCharCount: Int?
    var editorSettings = EditorSettings()

    /// 本文が空か（「何か書いてください」の案内を出す）。
    var isEmpty: Bool { !isLoading && lineCount == 0 }
}

/// メモ編集画面の一回きりのイベント。
enum MemoEditEvent: Equatable, Sendable {
    /// 読み込んだ本文を入力欄に入れる（画面を開いたときに1回だけ）。
    /// 文字色は画面のテーマで決まるので、装飾付きの本文への変換は画面側で行う。
    case setInitialText(html: String, isNewMemo: Bool)
    /// メモが見つからない（ゴミ箱に入った・消された）。画面を閉じる。
    case notFound
}

/// メモ編集画面の ViewModel（Android 版の MemoEditViewModel にあたる）。
///
/// 保存のタイミング:
/// - 入力が止まってから3秒後（強制終了などに備えた途中保存）
/// - 画面を閉じるとき・アプリが裏に回るとき（Android の onPause にあたる `onLeave`）
/// 前回保存した内容と同じなら、DB を読みに行かずにスキップする。
///
/// 本文が空のときは保存しない。
/// - 開いたときからあるメモを空にして閉じようとしたとき: 画面側で確認ダイアログを出す（`shouldConfirmDeleteOnLeave`）
///   - 削除する → `onDeleteConfirmed`（ゴミ箱へ）
///   - 元に戻して閉じる → `onRevertAndClose`（開いたときの本文・更新日に戻す）
/// - この画面で新しく作ったメモを空にして閉じたとき: 確認なしで破棄する（開いたときには無かったメモなので）
///
/// 保存は `SerialTaskQueue` で1つずつ行い、画面を閉じた後も最後まで行う。
@Observable
final class MemoEditViewModel {
    /// 入力が止まってから自動保存するまでの時間（Android と同じ3秒）。
    static let autoSaveDelay: Duration = .seconds(3)

    private(set) var uiState = MemoEditUiState()

    private let folderId: Int64?
    private var memoId: Int64?
    /// この画面で新しく作ったメモか（開いたときにはまだ無かった）
    private let isCreatedHere: Bool
    /// 読み込みが終わるまでは保存しない
    private var isLoaded = false
    /// 削除・元に戻す・破棄の後は保存しない
    private var isFinished = false
    /// 本文が空（空白だけ）か。確認ダイアログが要るかの判定に使う（変わったときだけ画面に知らせる）
    private var isContentBlank = true
    /// 入力中の本文（装飾なし）
    @ObservationIgnored private var currentPlainText = ""

    @ObservationIgnored private var hasStartedLoading = false
    /// 開いたときの内容（既存メモのみ）。「元に戻して閉じる」で使う
    @ObservationIgnored private var original: Memo?
    /// 入力中の本文の最新（閉じるとき・裏に回るときに保存する）。まだ入力していなければ nil
    @ObservationIgnored private var latestContent: NSAttributedString?
    /// 最後に保存した（または読み込んだ）HTML。同じ内容なら保存をスキップする
    @ObservationIgnored private var lastSavedHtml: String?
    @ObservationIgnored private var autoSaveTask: Task<Void, Never>?
    @ObservationIgnored private var countTask: Task<Void, Never>?
    @ObservationIgnored private let saveQueue = SerialTaskQueue()
    @ObservationIgnored private let eventChannel = EventChannel<MemoEditEvent>()
    @ObservationIgnored private let autoSaveDelay: Duration

    private let getMemo: GetMemoUseCase
    private let saveMemo: SaveMemoUseCase
    private let moveMemoToTrash: MoveMemoToTrashUseCase
    private let revertMemo: RevertMemoUseCase
    private let discardMemo: DiscardMemoUseCase
    private let observeEditorSettings: ObserveEditorSettingsUseCase

    init(
        memoId: Int64?,
        folderId: Int64?,
        getMemo: GetMemoUseCase,
        saveMemo: SaveMemoUseCase,
        moveMemoToTrash: MoveMemoToTrashUseCase,
        revertMemo: RevertMemoUseCase,
        discardMemo: DiscardMemoUseCase,
        observeEditorSettings: ObserveEditorSettingsUseCase,
        autoSaveDelay: Duration = MemoEditViewModel.autoSaveDelay
    ) {
        self.memoId = memoId
        self.folderId = folderId
        self.isCreatedHere = memoId == nil
        self.getMemo = getMemo
        self.saveMemo = saveMemo
        self.moveMemoToTrash = moveMemoToTrash
        self.revertMemo = revertMemo
        self.discardMemo = discardMemo
        self.observeEditorSettings = observeEditorSettings
        self.autoSaveDelay = autoSaveDelay
    }

    func events() -> AsyncStream<MemoEditEvent> { eventChannel.stream() }

    /// メモを読み込む（画面を開いたときに1回。View の `.task` から呼ぶ）。
    func load() async {
        guard !hasStartedLoading else { return }
        hasStartedLoading = true
        guard let id = memoId else {
            uiState.isLoading = false
            isLoaded = true
            eventChannel.send(.setInitialText(html: "", isNewMemo: true))
            return
        }
        do {
            guard let memo = try await getMemo(memoId: id) else {
                eventChannel.send(.notFound)
                return
            }
            original = memo
            lastSavedHtml = memo.html
            setPlainText(memo.plainText)
            uiState.isLoading = false
            updateCounts(memo.plainText)
            isLoaded = true
            eventChannel.send(.setInitialText(html: memo.html, isNewMemo: false))
        } catch {
            AppLog.error("メモを読めなかった: \(error)")
            eventChannel.send(.notFound)
        }
    }

    /// 文字の大きさ・行間を監視する（画面が出ている間）。
    func observeSettings() async {
        for await settings in observeEditorSettings() {
            uiState.editorSettings = settings
        }
    }

    /// 本文（文字または書式）が変わったとき。表示を更新し、入力が止まったら自動保存する。
    /// - Parameter content: 本文のコピー（後から書き換わらないもの）
    func onContentChanged(_ content: NSAttributedString) {
        guard isLoaded else { return }
        latestContent = content
        setPlainText(content.string)
        updateCounts(content.string)
        autoSaveTask?.cancel()
        let delay = autoSaveDelay
        autoSaveTask = Task { [weak self] in
            try? await Task.sleep(for: delay)
            guard !Task.isCancelled else { return }
            self?.save(content)
        }
    }

    /// 選んでいる文字が変わったとき。選んでいなければ nil。
    func onSelectionChanged(selectedText: String?) {
        uiState.selectedCharCount = selectedText.map(CharCounter.countChars)
    }

    /// 画面を閉じるとき（isClosing = true）・アプリが裏に回るとき（false）。すぐに保存する（Android の onPause）。
    /// ここで作ったメモを空にして閉じるときは破棄する。
    func onLeave(isClosing: Bool) {
        guard isLoaded else { return }
        autoSaveTask?.cancel()
        if isClosing && isCreatedHere && currentPlainText.isBlank {
            finish { [discardMemo] id in try await discardMemo(memoId: id) }
            return
        }
        if let content = latestContent { save(content) }
    }

    /// 閉じる前に「空のメモを削除しますか？」を確認する必要があるか。
    /// 開いたときからあるメモの本文を空にしたとき（ここで作ったメモは確認せずに破棄する）。
    var shouldConfirmDeleteOnLeave: Bool {
        isLoaded && !isFinished && !isCreatedHere && memoId != nil && isContentBlank
    }

    /// 確認ダイアログで「削除する」を選んだとき。メモをゴミ箱へ移す（30日以内なら戻せる）。
    func onDeleteConfirmed() {
        finish { [moveMemoToTrash] id in try await moveMemoToTrash(memoId: id) }
    }

    /// 確認ダイアログで「元に戻して閉じる」を選んだとき。開いたときの本文・更新日に戻す（途中で自動保存していなければ何もしない）。
    func onRevertAndClose() {
        let original = original
        finish { [weak self, revertMemo] _ in
            guard let original, self?.lastSavedHtml != original.html else { return }
            try await revertMemo(original: original)
        }
    }

    /// 保存がすべて終わるまで待つ（テスト用）。
    func waitForPendingSaves() async {
        await saveQueue.waitUntilIdle()
    }

    // MARK: 内部

    private func setPlainText(_ text: String) {
        currentPlainText = text
        let blank = text.isBlank
        if blank != isContentBlank { isContentBlank = blank }
    }

    /// 以降の保存を止め、最後の処理を保存と同じ順番待ちの中で行う。
    private func finish(_ action: @escaping @MainActor (_ memoId: Int64) async throws -> Void) {
        autoSaveTask?.cancel()
        isFinished = true
        saveQueue.enqueue { [self] in
            guard let id = memoId else { return }
            do {
                try await action(id)
            } catch {
                AppLog.error("メモの後始末に失敗: \(error)")
            }
        }
    }

    private func save(_ content: NSAttributedString) {
        guard !isFinished else { return }
        let html = MemoHtml.toHtml(content)
        let plainText = content.string
        saveQueue.enqueue { [self] in
            guard !isFinished, html != lastSavedHtml else { return } // 前回と同じ内容なら DB に触らない
            do {
                let result = try await saveMemo(memoId: memoId, folderId: folderId, html: html, plainText: plainText)
                if result != .skippedEmpty { lastSavedHtml = html }
                if case .created(let id) = result { memoId = id }
            } catch {
                AppLog.error("メモを保存できなかった: \(error)")
            }
        }
    }

    /// 文字数・行数を数える（長いメモでも入力が重くならないよう、別のスレッドで数える）。
    private func updateCounts(_ text: String) {
        countTask?.cancel()
        countTask = Task { [weak self] in
            let counts = await Task.detached(priority: .userInitiated) {
                (CharCounter.countChars(text), CharCounter.countLines(text))
            }.value
            guard !Task.isCancelled, let self else { return }
            uiState.charCount = counts.0
            uiState.lineCount = counts.1
        }
    }
}
