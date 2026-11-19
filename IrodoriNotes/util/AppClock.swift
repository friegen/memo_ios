import Foundation

/// 現在時刻（epoch millis）を返す。
/// UseCase のテストで時刻を固定できるように、`Date()` を直接使わずにこれを渡す
/// （テストでは継承して `now()` を差し替える）。
nonisolated class AppClock: @unchecked Sendable {
    init() {}

    func now() -> Int64 { Int64((Date().timeIntervalSince1970 * 1000).rounded()) }
}
