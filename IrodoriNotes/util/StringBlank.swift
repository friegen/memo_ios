import Foundation

nonisolated extension String {
    /// 空か、空白・改行だけか（Kotlin の isBlank にあたる）。
    var isBlank: Bool { allSatisfy(\.isWhitespace) }
}
