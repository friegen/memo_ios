import Foundation

/// 2つの流れの最新の値をまとめて流す（Android の Flow の combine にあたる）。
/// 両方の流れから1回ずつ値が来てから流し始め、その後はどちらかが変わるたびに流す。
nonisolated func combineLatest<A: Sendable, B: Sendable>(
    _ first: AsyncThrowingStream<A, any Error>,
    _ second: AsyncStream<B>
) -> AsyncThrowingStream<(A, B), any Error> {
    AsyncThrowingStream { continuation in
        let latest = LatestPair<A, B>()
        let task = Task {
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    group.addTask {
                        for try await value in first {
                            if let pair = await latest.setFirst(value) { continuation.yield(pair) }
                        }
                    }
                    group.addTask {
                        for await value in second {
                            if let pair = await latest.setSecond(value) { continuation.yield(pair) }
                        }
                    }
                    try await group.waitForAll()
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in task.cancel() }
    }
}

/// `combineLatest` が持っている、それぞれの流れの最新の値。
private actor LatestPair<A: Sendable, B: Sendable> {
    private var first: A?
    private var second: B?

    func setFirst(_ value: A) -> (A, B)? {
        first = value
        return second.map { (value, $0) }
    }

    func setSecond(_ value: B) -> (A, B)? {
        second = value
        return first.map { ($0, value) }
    }
}
