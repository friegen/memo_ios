import Foundation

/// データサイズの表示（例: 512 B / 8.5 KB / 421 KB / 3.2 MB）。Android 版の DataSizeText と同じ決まり。
/// 1KB = 1024 バイトで数える。
nonisolated enum DataSizeText {
    private static let kb: Int64 = 1024
    private static let mb: Int64 = 1024 * 1024

    static func format(_ bytes: Int64, bundle: Bundle = .main, locale: Locale = .current) -> String {
        let number = NumberFormatter()
        number.numberStyle = .decimal
        number.locale = locale
        if bytes < kb {
            return L10n.format("data_size_bytes", number.string(from: NSNumber(value: bytes)) ?? "\(bytes)", bundle: bundle)
        } else if bytes < mb {
            // 10KB 未満だけ小数1桁まで（例: 8.5 KB）
            number.maximumFractionDigits = bytes < 10 * kb ? 1 : 0
            return L10n.format("data_size_kb", number.string(from: NSNumber(value: Double(bytes) / Double(kb))) ?? "", bundle: bundle)
        } else {
            number.maximumFractionDigits = 1
            return L10n.format("data_size_mb", number.string(from: NSNumber(value: Double(bytes) / Double(mb))) ?? "", bundle: bundle)
        }
    }
}
