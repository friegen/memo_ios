import Foundation

/// リワード広告を出せなかったときに、広告なしで作らせるか、広告ブロックをオフにするようお願いするかを決める。
final class DecideRewardedAdFallbackUseCase {
    private let networkStatus: NetworkStatus

    init(networkStatus: NetworkStatus) {
        self.networkStatus = networkStatus
    }

    func callAsFunction(_ failure: AdLoadFailure) -> RewardedFallback {
        AdPolicy.rewardedFallback(failure, isOnline: networkStatus.isOnline())
    }
}
