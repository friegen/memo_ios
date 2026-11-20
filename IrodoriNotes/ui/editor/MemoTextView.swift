import SwiftUI
import UIKit

/// 編集画面から入力欄（UITextView）を操作するための窓口。
/// SwiftUI の画面から「本文を入れる」「キーボードを出す・閉じる」を呼ぶのに使う（Android の binding.memoText にあたる）。
final class MemoEditorController {
    fileprivate weak var textView: UITextView?
    fileprivate var editorSettings = EditorSettings()

    /// 本文を入れる（「本文が変わった」扱いにはしない）。
    func setText(_ text: String) {
        guard let textView else { return }
        textView.attributedText = NSAttributedString(string: text, attributes: Self.attributes(for: editorSettings))
        textView.contentOffset = .zero // 本文の先頭を見せる（カーソルは iOS の標準どおり、タップした位置に置く）
    }

    /// キーボードを出す（新しいメモを開いたとき）。
    func focus() {
        textView?.becomeFirstResponder()
    }

    /// キーボードを閉じる（カーソルはそのまま）。
    func hideKeyboard() {
        textView?.resignFirstResponder()
    }

    /// 文字の大きさ・行間（Android の applyEditorSettings にあたる）。sp と同じく、端末の文字の大きさの設定にも合わせる。
    static func attributes(for settings: EditorSettings) -> [NSAttributedString.Key: Any] {
        let font = UIFontMetrics(forTextStyle: .body).scaledFont(for: .systemFont(ofSize: settings.fontSize.sizePt))
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineHeightMultiple = settings.lineSpacing.multiplier
        return [.font: font, .paragraphStyle: paragraph, .foregroundColor: UIColor.label]
    }

    fileprivate func apply(_ settings: EditorSettings) {
        guard let textView else { return }
        editorSettings = settings
        let attributes = Self.attributes(for: settings)
        textView.typingAttributes = attributes
        let storage = textView.textStorage
        storage.beginEditing()
        storage.addAttributes(attributes, range: NSRange(location: 0, length: storage.length))
        storage.endEditing()
    }
}

/// メモの本文の入力欄。SwiftUI の TextEditor では細かい制御（入力の上限・選んだ範囲など）ができないので、UIKit の UITextView を使う。
struct MemoTextView: UIViewRepresentable {
    let controller: MemoEditorController
    let settings: EditorSettings
    /// 本文が変わった（入力・削除・貼り付け）。本文のコピーを渡す
    let onTextChange: (NSAttributedString) -> Void
    /// 選んでいる文字が変わった。選んでいなければ nil
    let onSelectionChange: (String?) -> Void
    /// 1メモの文字数の上限に達して、入力を止めた（または入る分だけにした）
    let onLimitReached: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.delegate = context.coordinator
        textView.backgroundColor = .clear
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.adjustsFontForContentSizeCategory = true
        textView.accessibilityIdentifier = "memo_text"
        controller.textView = textView
        controller.apply(settings)
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        if settings != controller.editorSettings { controller.apply(settings) }
    }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MemoTextView

        init(_ parent: MemoTextView) {
            self.parent = parent
        }

        func textViewDidChange(_ textView: UITextView) {
            parent.onTextChange(NSAttributedString(attributedString: textView.attributedText))
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            let range = textView.selectedRange
            parent.onSelectionChange(range.length > 0 ? (textView.text as NSString).substring(with: range) : nil)
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard let limited = MaxCharsLimiter.limit(
                current: textView.text, range: range, replacement: text, maxChars: MemoPolicy.maxChars)
            else { return true }
            parent.onLimitReached()
            // 入る分だけ入れる（貼り付けで上限を超えたとき）
            if !limited.isEmpty,
               let start = textView.position(from: textView.beginningOfDocument, offset: range.location),
               let end = textView.position(from: start, offset: range.length),
               let textRange = textView.textRange(from: start, to: end)
            {
                textView.replace(textRange, withText: limited)
            }
            return false
        }
    }
}
