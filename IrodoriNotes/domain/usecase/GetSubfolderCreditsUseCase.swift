import Foundation

/// リワード広告を見て得た「フォルダの中にフォルダを作れる残りの数」。
final class GetSubfolderCreditsUseCase {
    private let adStateRepository: AdStateRepository

    init(adStateRepository: AdStateRepository) {
        self.adStateRepository = adStateRepository
    }

    func callAsFunction() -> Int {
        adStateRepository.subfolderCredits
    }
}
