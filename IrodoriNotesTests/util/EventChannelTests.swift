import Foundation
import Testing
@testable import IrodoriNotes

/// ViewModel から画面への一回きりのイベントの通り道（Android の Channel にあたる）。
struct EventChannelTests {

    @Test func deliversEventsToSubscriber() async {
        let channel = EventChannel<Int>()
        var iterator = channel.stream().makeAsyncIterator()

        channel.send(1)
        channel.send(2)

        #expect(await iterator.next() == 1)
        #expect(await iterator.next() == 2)
    }

    @Test func keepsEventsSentWhileNobodyIsListening() async {
        let channel = EventChannel<Int>()
        channel.send(1) // まだ受け取っている画面がない

        var iterator = channel.stream().makeAsyncIterator()

        #expect(await iterator.next() == 1)
    }

    /// 画面が消えて（受け取りをやめて）出直しても、また受け取れる。
    @Test func canSubscribeAgainAfterPreviousSubscriberStopped() async throws {
        let channel = EventChannel<Int>()
        let first = Task {
            for await _ in channel.stream() {}
        }
        try await Task.sleep(for: .milliseconds(50))
        first.cancel()
        try await Task.sleep(for: .milliseconds(50))

        channel.send(3) // 前の受け取りが終わった後に送る
        var iterator = channel.stream().makeAsyncIterator()

        #expect(await iterator.next() == 3)
    }
}
