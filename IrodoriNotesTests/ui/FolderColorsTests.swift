import Foundation
import Testing
import UIKit
@testable import IrodoriNotes

/// フォルダの色（Android 版の FolderColorsTest と同じ内容）。
struct FolderColorsTests {

    /// 全色、ライト・ダークとも、選んだ文字色とのコントラスト比が 4.5 以上（WCAG AA）。
    @Test(arguments: [UIUserInterfaceStyle.light, .dark])
    func everyColorIsReadable(style: UIUserInterfaceStyle) throws {
        for color in FolderColor.allCases where color != .default {
            let background = try #require(color.uiColor, "\(color) の色がない")
                .resolvedColor(with: UITraitCollection(userInterfaceStyle: style))
            let content = FolderColors.contentColor(on: background)
            #expect(FolderColors.contrast(content, background) >= 4.5, "\(color)（\(style == .dark ? "ダーク" : "ライト")）が読みにくい")
        }
    }

    /// ライトの赤（中間の明るさ）でも黒を選ぶ（明るさ 0.5 で決めると白になって読みにくかった）。
    @Test func lightRedUsesBlackText() throws {
        let red = try #require(FolderColor.red.uiColor).resolvedColor(with: UITraitCollection(userInterfaceStyle: .light))
        #expect(FolderColors.contentColor(on: red) == .black)
    }

    @Test func contentsText() throws {
        let path = try #require(Bundle(for: BundleToken.self).path(forResource: "ja", ofType: "lproj"))
        let ja = try #require(Bundle(path: path))
        let locale = Locale(identifier: "ja_JP")
        #expect(folderContentsText(FolderContents(folderCount: 2, memoCount: 5), bundle: ja, locale: locale) == "フォルダ2個、メモ5件")
        #expect(folderContentsText(FolderContents(folderCount: 0, memoCount: 1), bundle: ja, locale: locale) == "メモ1件")
        #expect(folderContentsText(FolderContents(folderCount: 0, memoCount: 0), bundle: ja, locale: locale) == "")

        let enPath = try #require(Bundle(for: BundleToken.self).path(forResource: "en", ofType: "lproj"))
        let en = try #require(Bundle(path: enPath))
        #expect(folderContentsText(FolderContents(folderCount: 1, memoCount: 2), bundle: en, locale: Locale(identifier: "en_US"))
            == "1 folder, 2 notes")
    }
}
