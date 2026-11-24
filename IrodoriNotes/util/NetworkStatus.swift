import Foundation
import Network

/// 端末がインターネットにつながっているか（Android 版の NetworkStatus にあたる）。
/// リワード広告を出せなかったとき、オフラインなのか（広告なしで作れる）、広告ブロックなのか（オフにするようお願いする）を見分けるのに使う。
/// テストでは継承して結果を決めるものに差し替える（そのため final にしない）。
nonisolated class NetworkStatus: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let lock = NSLock()
    private var satisfied = true

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            lock.withLock { self.satisfied = path.status == .satisfied }
        }
        monitor.start(queue: DispatchQueue(label: "xyz.friegen.memo.network"))
    }

    deinit {
        monitor.cancel()
    }

    func isOnline() -> Bool {
        lock.withLock { satisfied }
    }
}
