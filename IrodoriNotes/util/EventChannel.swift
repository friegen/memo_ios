import Foundation

/// ViewModel から画面への一回きりのイベント（画面遷移・「元に戻す」の表示など）の通り道。
/// Android の `Channel(BUFFERED)` + `receiveAsFlow()` にあたる。
///
/// - 画面は `stream()` で受け取る（View の `.task` で for await する）。画面が出直すたびに新しく受け取り直せる
///   （AsyncStream は受け取りをやめると終わってしまうので、受け取るたびに作り直す）
/// - 受け取っている画面がないときに送ったイベントは取っておき、次に受け取ったときに渡す
final class EventChannel<Event: Sendable> {
    private var continuation: AsyncStream<Event>.Continuation?
    private var pending: [Event] = []

    init() {}

    /// イベントを送る。受け取っている画面がなければ取っておく。
    func send(_ event: Event) {
        if let continuation, case .enqueued = continuation.yield(event) { return }
        continuation = nil // 受け取りが終わっていた
        pending.append(event)
    }

    /// イベントを受け取る流れ。前に作った流れは終わる（受け取るのは1つの画面だけ）。
    func stream() -> AsyncStream<Event> {
        continuation?.finish()
        let (stream, continuation) = AsyncStream<Event>.makeStream()
        self.continuation = continuation
        for event in pending { continuation.yield(event) }
        pending.removeAll()
        return stream
    }
}
