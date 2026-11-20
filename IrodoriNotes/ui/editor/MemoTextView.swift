import SwiftUI
import UIKit

/// 書式パネルに表示する状態。
struct FormatPanelState: Equatable {
    /// ボタンの押された状態（選んだ文字の書式、カーソルだけならこれから入力する書式）
    var format = TextFormat.none
    /// 選んでいる色の丸。nil なら「既定の色」、`.mixed` は色が混ざっていてどれも選ばない
    var selectedColor: ColorSelection = .default

    enum ColorSelection: Equatable {
        case `default`
        case color(String)
        case mixed
    }
}

/// 編集画面から入力欄（UITextView）を操作するための窓口（Android の binding.memoText と書式の操作にあたる）。
///
/// 書式の決まり（Android 版 v1.5・v1.9 と同じ）:
/// - 文字を選んでいるとき: パネルのボタンで、選んだ文字の書式を付け外しする（選んだまま何度でも）
/// - カーソルだけのとき: パネルのボタンで「これから入力する文字の書式」を選ぶ。パネルを開いた直後・カーソルを動かした後は、
///   カーソルの直前の文字の書式から始まる
/// - パネルを閉じているときに入力した文字は書式なし
/// - 入力した文字の書式は UITextView の typingAttributes で付ける（日本語の変換中の文字・貼り付けにも効く）
final class MemoEditorController {
    fileprivate weak var textView: UITextView?
    fileprivate var editorSettings = EditorSettings()

    /// 書式パネルを開いているか
    private(set) var isFormatPanelOpen = false
    /// これから入力する文字の書式（パネルを開いているとき）
    private var typingFormat = TextFormat.none

    /// 本文が変わった（書式の変更も含む）ときに呼ぶ（MemoTextView が設定する）
    fileprivate var onContentChange: ((NSAttributedString) -> Void)?
    /// 書式パネルの表示を変えるときに呼ぶ
    var onFormatPanelStateChange: ((FormatPanelState) -> Void)?

    /// 保存形式の HTML を、今の文字の大きさ・テーマの色で入力欄に入れる（「本文が変わった」扱いにはしない）。
    func setHTML(_ html: String) {
        guard let textView else { return }
        let text = NSMutableAttributedString(attributedString: MemoHtml.fromHtml(html))
        MemoTextAttributes.applyVisuals(to: text, settings: editorSettings)
        textView.attributedText = text
        textView.contentOffset = .zero // 本文の先頭を見せる（カーソルは iOS の標準どおり、タップした位置に置く）
        updateTypingAttributes()
    }

    /// キーボードを出す（新しいメモを開いたとき）。
    func focus() {
        textView?.becomeFirstResponder()
    }

    /// キーボードを閉じる（カーソルはそのまま）。
    func hideKeyboard() {
        textView?.resignFirstResponder()
    }

    // MARK: 書式パネル

    func setFormatPanelOpen(_ open: Bool) {
        guard open != isFormatPanelOpen else { return }
        isFormatPanelOpen = open
        if open { syncFormatWithSelection() } else { updateTypingAttributes() }
    }

    /// 太字・斜体・下線のボタン。
    func toggle(_ style: MemoTextStyle) {
        guard let textView else { return }
        let range = textView.selectedRange
        if range.length == 0 {
            typingFormat = typingFormat.with(style, !typingFormat.has(style))
            updateTypingAttributes()
            notifyPanelState()
            return
        }
        editSelection(textView, range) { TextStyler.toggleStyle($0, range, style) }
    }

    /// 色の丸。nil は「既定の色」（色を外す）。
    func setColor(_ colorKey: String?) {
        guard let textView else { return }
        let range = textView.selectedRange
        if range.length == 0 {
            typingFormat.colorKey = colorKey
            updateTypingAttributes()
            notifyPanelState()
            return
        }
        editSelection(textView, range) { TextStyler.setColor($0, range, colorKey) }
    }

    /// 選んだ文字の書式を変えて、見た目を付け直し、保存の対象にする（書式の変更は文字の変更として通知されないため）。
    private func editSelection(_ textView: UITextView, _ range: NSRange, _ edit: (NSMutableAttributedString) -> Void) {
        let storage = textView.textStorage
        storage.beginEditing()
        edit(storage)
        MemoTextAttributes.applyVisuals(to: storage, range: range, settings: editorSettings)
        storage.endEditing()
        textView.selectedRange = range // 選んだまま続けて付け外しできるように
        onContentChange?(NSAttributedString(attributedString: textView.attributedText))
        syncFormatWithSelection()
    }

    /// 選んでいる文字（カーソルだけなら直前の文字）の書式を、パネルの表示とこれから入力する書式にする。
    fileprivate func syncFormatWithSelection() {
        guard isFormatPanelOpen, let textView else {
            updateTypingAttributes()
            return
        }
        typingFormat = TextStyler.formatOf(textView.attributedText, textView.selectedRange)
        updateTypingAttributes()
        notifyPanelState()
    }

    /// 入力する文字の書式: パネルを開いていれば選んだ書式、閉じていれば書式なし。
    fileprivate func updateTypingAttributes() {
        guard let textView else { return }
        let format = isFormatPanelOpen ? typingFormat : .none
        textView.typingAttributes = MemoTextAttributes.attributes(for: format, settings: editorSettings)
    }

    private func notifyPanelState() {
        guard let textView else { return }
        let range = textView.selectedRange
        let selectedColor: FormatPanelState.ColorSelection
        if let key = typingFormat.colorKey {
            selectedColor = .color(key)
        } else if range.length > 0 && TextStyler.hasAnyColor(textView.attributedText, range) {
            selectedColor = .mixed // 色が混ざっている
        } else {
            selectedColor = .default
        }
        onFormatPanelStateChange?(FormatPanelState(format: typingFormat, selectedColor: selectedColor))
    }

    // MARK: 文字の大きさ・行間

    fileprivate func apply(_ settings: EditorSettings) {
        editorSettings = settings
        guard let textView else { return }
        MemoTextAttributes.applyVisuals(to: textView.textStorage, settings: settings)
        updateTypingAttributes()
    }
}

/// メモの本文の入力欄。SwiftUI の TextEditor では細かい制御（入力の上限・選んだ範囲・入力する文字の書式など）が
/// できないので、UIKit の UITextView を使う。
struct MemoTextView: UIViewRepresentable {
    let controller: MemoEditorController
    let settings: EditorSettings
    /// 本文が変わった（入力・削除・貼り付け・書式の変更）。本文のコピーを渡す
    let onTextChange: (NSAttributedString) -> Void
    /// 選んでいる文字が変わった。選んでいなければ nil
    let onSelectionChange: (String?) -> Void
    /// 1メモの文字数の上限に達して、入力を止めた（または入る分だけにした）
    let onLimitReached: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> UITextView {
        let textView = Self.makeTextView()
        textView.delegate = context.coordinator
        controller.textView = textView
        controller.onContentChange = onTextChange
        controller.apply(settings)
        return textView
    }

    /// 入力欄を作る（テストでも使う）。
    static func makeTextView() -> UITextView {
        // 従来の描き方（TextKit 1）を使う。新しい描き方（TextKit 2）は文字を傾ける指定（.obliqueness）を描かず、
        // 斜体が出ないため（日本語のフォントには斜体がないので、Android と同じく文字を傾けて斜体にしている）
        let textView = UITextView(usingTextLayoutManager: false)
        textView.backgroundColor = .clear
        textView.alwaysBounceVertical = true
        textView.keyboardDismissMode = .interactive
        textView.textContainerInset = UIEdgeInsets(top: 12, left: 12, bottom: 12, right: 12)
        textView.adjustsFontForContentSizeCategory = true
        // 他のアプリからの貼り付けは文字だけにする（保存できない装飾が紛れ込まないように。Android と同じ）。
        // false なら、iOS は貼り付けた文字に typingAttributes（パネルの状態の書式）を付ける
        textView.allowsEditingTextAttributes = false
        textView.accessibilityIdentifier = "memo_text"
        return textView
    }

    func updateUIView(_ textView: UITextView, context: Context) {
        context.coordinator.parent = self
        controller.onContentChange = onTextChange
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
            // iOS はカーソルが動くと typingAttributes を直前の文字の書式に戻すので、パネルの状態に合わせ直す
            parent.controller.syncFormatWithSelection()
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
