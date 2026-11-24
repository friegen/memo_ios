import Foundation

/// リワード広告を最後まで見たので、フォルダの中に作れるフォルダの数を増やす（`AdPolicy.subfoldersPerReward`）。
final class GrantSubfolderCreditsUseCase {
    private let adStateRepository: AdStateRepository

    init(adStateRepository: AdStateRepository) {
        self.adStateRepository = adStateRepository
    }

    func callAsFunction() {
        adStateRepository.addSubfolderCredits(AdPolicy.subfoldersPerReward)
    }
}
