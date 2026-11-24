import Foundation

/// アプリを開いた（新しく起動した・バックグラウンドから戻った）ことを記録する。
final class RecordAppLaunchUseCase {
    private let adStateRepository: AdStateRepository

    init(adStateRepository: AdStateRepository) {
        self.adStateRepository = adStateRepository
    }

    func callAsFunction() {
        _ = adStateRepository.incrementLaunchCount()
    }
}
