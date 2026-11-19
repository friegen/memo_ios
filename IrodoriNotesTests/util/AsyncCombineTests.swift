import Foundation
import Testing
@testable import IrodoriNotes

/// 2つの流れの最新の値をまとめる処理（Android の combine にあたる）。
struct AsyncCombineTests {

    @Test func emitsAfterBothAndOnEachChange() async throws {
        let (first, firstInput) = AsyncThrowingStream<Int, any Error>.makeStream()
        let (second, secondInput) = AsyncStream<String>.makeStream()
        var iterator = combineLatest(first, second).makeAsyncIterator()

        firstInput.yield(1)
        secondInput.yield("a") // 両方そろってから流れる
        #expect(try await iterator.next().map { "\($0.0)\($0.1)" } == "1a")

        firstInput.yield(2)
        #expect(try await iterator.next().map { "\($0.0)\($0.1)" } == "2a")

        secondInput.yield("b")
        #expect(try await iterator.next().map { "\($0.0)\($0.1)" } == "2b")
    }
}
