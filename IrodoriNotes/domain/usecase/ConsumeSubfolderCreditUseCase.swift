import Foundation

/// フォルダの中にフォルダを作ったので、残りの数を1つ使う（0 のときは 0 のまま）。
final class ConsumeSubfolderCreditUseCase {
    private let adStateRepository: AdStateRepository

    init(adStateRepository: AdStateRepository) {
        self.adStateRepository = adStateRepository
    }

    func callAsFunction() {
        adStateRepository.consumeSubfolderCredit()
    }
}
