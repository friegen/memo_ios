import Foundation

/// アプリ起動広告を出したことを記録する（次に出せるまでの間隔の起点）。
final class RecordAppOpenAdShownUseCase {
    private let adStateRepository: AdStateRepository
    private let clock: AppClock

    init(adStateRepository: AdStateRepository, clock: AppClock) {
        self.adStateRepository = adStateRepository
        self.clock = clock
    }

    func callAsFunction() {
        adStateRepository.setAppOpenAdLastShownAt(clock.now())
    }
}
