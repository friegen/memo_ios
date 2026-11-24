import Foundation

/// 今のデータサイズ（バイト）。iCloud バックアップなどの対象になるアプリのデータの合計。
final class GetDataUsageUseCase {
    private let storageRepository: StorageRepository

    init(storageRepository: StorageRepository) {
        self.storageRepository = storageRepository
    }

    func callAsFunction() async -> Int64 {
        await storageRepository.getDataBytes()
    }
}
