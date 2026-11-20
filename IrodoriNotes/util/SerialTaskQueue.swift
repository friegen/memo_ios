import Foundation

/// 処理を1つずつ順番に行う（Android の Mutex.withLock にあたる）。保存が重なって新規メモが二重に作られないようにする。
///
/// 入れた処理は、画面を閉じた後も最後まで行われる（Android の AppScope で保存していたのと同じ）。
final class SerialTaskQueue {
    private var last: Task<Void, Never>?

    init() {}

    /// 前の処理が終わってから `work` を行う。
    @discardableResult
    func enqueue(_ work: @escaping @MainActor () async -> Void) -> Task<Void, Never> {
        let previous = last
        let task = Task {
            await previous?.value
            await work()
        }
        last = task
        return task
    }

    /// 入れた処理がすべて終わるまで待つ（テスト用）。
    func waitUntilIdle() async {
        while let task = last {
            await task.value
            if last == task { return }
        }
    }
}
