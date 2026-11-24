import Foundation

/// アプリで使っているオープンソースのライブラリ（設定の「オープンソースライセンス」に出す）。
nonisolated struct OssLibrary: Hashable, Identifiable, Sendable {
    /// Swift Package Manager のパッケージ名（Package.resolved の identity）
    let id: String
    let name: String
    /// 使っている版。分からなければ nil
    let version: String?
    /// ライセンスの名前（例: MIT License）
    let licenseName: String
    /// ライセンスの全文。なければ空
    let licenseText: String
}
