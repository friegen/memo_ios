import Foundation

/// 使っているオープンソースのライブラリの一覧（名前の順）。
final class GetOssLibrariesUseCase {
    private let licenseRepository: LicenseRepository

    init(licenseRepository: LicenseRepository) {
        self.licenseRepository = licenseRepository
    }

    func callAsFunction() async throws -> [OssLibrary] {
        try await licenseRepository.getLibraries()
    }
}
