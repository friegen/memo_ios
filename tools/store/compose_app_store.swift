// App Store のスクリーンショット（6.9 インチ・1320×2868）を作る。Android 版の tools/store/compose.py と同じ見た目・同じ見出し。
//
// 使い方（リポジトリのルートで）:
//   swift tools/store/compose_app_store.swift
// 入力: build/store-screens/<言語>_<画面>.png（tools/store/StoreScreenshotTests.swift.txt で撮る）
// 出力: docs/store/app-store/screenshots/<言語>/01.jpg 〜 07.jpg
import AppKit
import UniformTypeIdentifiers

let W = 1320, H = 2868
let top = NSColor(srgbRed: 10 / 255, green: 108 / 255, blue: 214 / 255, alpha: 1)    // アプリの青 #0A6CD6
let bottom = NSColor(srgbRed: 77 / 255, green: 160 / 255, blue: 245 / 255, alpha: 1)  // 明るい青
let accent = NSColor(srgbRed: 1, green: 228 / 255, blue: 92 / 255, alpha: 1)          // 黄（アイコンのリボンの色）
let subColor = NSColor(srgbRed: 230 / 255, green: 240 / 255, blue: 1, alpha: 1)

let screens = ["editor_color", "folders", "editor_select", "memos", "folder_detail", "export", "dark_memos"]
// 見出し2行（{...} は黄色）と小さい文字。Android 版の compose.py の SETS・CAPTIONS と同じ
let captions: [String: [([String], String?)]] = [
    "ja": [(["文字に{色}をつけて", "見やすいメモに"], "太字・斜体・下線も"), (["{色分けフォルダ}で", "すっきり整理"], nil),
           (["{文字数}が", "ひと目でわかる"], "選んだ範囲の文字数も表示"), (["大事なメモは", "{ロック}＆{ピン留め}"], nil),
           (["フォルダの中に", "{フォルダ}を作れる"], "最大5階層まで"), (["{PDF・画像・テキスト}で", "出力して共有"], nil),
           (["{ダークモード}", "にも対応"], nil)],
    "en": [(["Add {color}", "to your notes"], "Bold, italic, and underline, too"), (["Organize with", "{color-coded folders}"], nil),
           (["See your", "{character count}"], "Even for selected text"), (["{Lock} & {pin}", "important notes"], nil),
           (["{Folders}", "inside folders"], "Up to 5 levels"), (["{Export} to", "PDF, image, or text"], nil),
           (["{Dark mode}", "supported"], nil)],
    "es": [(["Dale {color}", "a tus notas"], "También negrita, cursiva y subrayado"), (["Organiza con", "{carpetas de colores}"], nil),
           (["Cuenta los {caracteres}", "de un vistazo"], "También del texto seleccionado"), (["{Bloquea} y {fija}", "tus notas importantes"], nil),
           (["{Carpetas}", "dentro de carpetas"], "Hasta 5 niveles"), (["{Exporta} a", "PDF, imagen o texto"], nil),
           (["Compatible con", "{modo oscuro}"], nil)],
    "pt": [(["Dê {cor}", "às suas notas"], "Negrito, itálico e sublinhado também"), (["Organize com", "{pastas coloridas}"], nil),
           (["Veja a {contagem}", "{de caracteres}"], "Até do texto selecionado"), (["{Bloqueie} e {fixe}", "notas importantes"], nil),
           (["{Pastas}", "dentro de pastas"], "Até 5 níveis"), (["{Exporte} para", "PDF, imagem ou texto"], nil),
           (["Compatível com", "{modo escuro}"], nil)],
    "fr": [(["Mettez de la {couleur}", "dans vos notes"], "Gras, italique et souligné aussi"), (["Organisez avec des", "{dossiers colorés}"], nil),
           (["Le {nombre de caractères}", "en un coup d’œil"], "Même pour le texte sélectionné"), (["{Verrouillez} et {épinglez}", "vos notes importantes"], nil),
           (["Des {dossiers}", "dans des dossiers"], "Jusqu’à 5 niveaux"), (["{Exportez} en", "PDF, image ou texte"], nil),
           (["{Mode sombre}", "disponible"], nil)],
    "de": [(["Bring {Farbe}", "in deine Notizen"], "Auch fett, kursiv und unterstrichen"), (["Ordnen mit", "{farbigen Ordnern}"], nil),
           (["{Zeichenanzahl}", "auf einen Blick"], "Auch für markierten Text"), (["Wichtige Notizen", "{sperren} & {anheften}"], nil),
           (["{Ordner}", "in Ordnern"], "Bis zu 5 Ebenen"), (["{Exportieren} als", "PDF, Bild oder Text"], nil),
           (["{Dunkles Design}", "verfügbar"], nil)],
    "ko": [(["글자에 {색}을 입혀", "보기 쉬운 메모로"], "굵게·기울임꼴·밑줄도"), (["{색깔 폴더}로", "깔끔하게 정리"], nil),
           (["{글자 수}를", "한눈에 확인"], "선택한 부분의 글자 수도 표시"), (["중요한 메모는", "{잠금} & {고정}"], nil),
           (["폴더 안에", "{폴더}를 만들 수 있어요"], "최대 5단계까지"), (["{PDF·이미지·텍스트}로", "내보내고 공유"], nil),
           (["{다크 모드}", "지원"], nil)],
    "zh-Hant": [(["為文字加上{顏色}", "記事更好讀"], "也能使用粗體、斜體、底線"), (["用{彩色資料夾}", "整理得清清楚楚"], nil),
                (["{字數}", "一眼就知道"], "也會顯示選取範圍的字數"), (["重要記事可以", "{鎖定}＆{釘選}"], nil),
                (["資料夾裡", "也能建立{資料夾}"], "最多 5 層"), (["以 {PDF・圖片・文字}", "匯出並分享"], nil),
                (["支援", "{深色模式}"], nil)],
    "id": [(["Beri {warna}", "pada catatan Anda"], "Juga tebal, miring, dan garis bawah"), (["Rapikan dengan", "{folder berwarna}"], nil),
           (["Lihat {jumlah karakter}", "sekilas"], "Juga untuk teks yang dipilih"), (["{Kunci} & {sematkan}", "catatan penting"], nil),
           (["{Folder}", "di dalam folder"], "Hingga 5 tingkat"), (["{Ekspor} ke", "PDF, gambar, atau teks"], nil),
           (["Mendukung", "{mode gelap}"], nil)],
]

func titleFont(_ lang: String, _ size: CGFloat) -> NSFont {
    switch lang {
    case "ja": NSFont(name: "HiraginoSans-W8", size: size)!
    case "ko": NSFont(name: "AppleSDGothicNeo-Heavy", size: size)!
    case "zh-Hant": NSFont(name: "PingFangTC-Semibold", size: size)!
    default: NSFont.systemFont(ofSize: size, weight: .black)
    }
}

func subFont(_ lang: String, _ size: CGFloat) -> NSFont {
    switch lang {
    case "ja": NSFont(name: "HiraginoSans-W6", size: size)!
    case "ko": NSFont(name: "AppleSDGothicNeo-Bold", size: size)!
    case "zh-Hant": NSFont(name: "PingFangTC-Medium", size: size)!
    default: NSFont.systemFont(ofSize: size, weight: .bold)
    }
}

/// {...} の部分を黄色にした文字列。
func rich(_ text: String, font: NSFont, color: NSColor) -> NSAttributedString {
    let out = NSMutableAttributedString()
    var accentOn = false
    var buffer = ""
    func flush() {
        if buffer.isEmpty { return }
        out.append(NSAttributedString(string: buffer, attributes: [.font: font, .foregroundColor: accentOn ? accent : color]))
        buffer = ""
    }
    for ch in text {
        if ch == "{" { flush(); accentOn = true } else if ch == "}" { flush(); accentOn = false } else { buffer.append(ch) }
    }
    flush()
    return out
}

/// 一番長い行が maxWidth に入る大きさ（size から小さくしていく）。
func fit(_ lines: [String], _ makeFont: (CGFloat) -> NSFont, start: CGFloat, maxWidth: CGFloat) -> CGFloat {
    var size = start
    while size > 30 {
        let f = makeFont(size)
        if lines.allSatisfy({ rich($0, font: f, color: .white).size().width <= maxWidth }) { return size }
        size -= 2
    }
    return size
}

func compose(lang: String, index: Int, screen: String, lines: [String], sub: String?, inDir: String, out: String) {
    guard let shot = NSImage(contentsOfFile: "\(inDir)/\(lang)_\(screen).png") else { print("ない: \(lang)_\(screen)"); return }
    let rep = NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: W, pixelsHigh: H, bitsPerSample: 8, samplesPerPixel: 4,
                               hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    let ctx = NSGraphicsContext(bitmapImageRep: rep)!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = ctx
    let cg = ctx.cgContext
    // 上から測った y を、下から測る座標に直す
    func flip(_ y: CGFloat, _ h: CGFloat) -> CGFloat { CGFloat(H) - y - h }

    // 背景: 縦のグラデーションと、いろどりの淡い丸（ぼかし）
    NSGradient(starting: top, ending: bottom)!.draw(in: NSRect(x: 0, y: 0, width: W, height: H), angle: -90)
    let blobColors: [(CGFloat, CGFloat, CGFloat, CGFloat)] = [(242, 139, 130, 0.38), (255, 228, 92, 0.33), (107, 191, 89, 0.33), (255, 255, 255, 0.22)]
    let spots: [(CGFloat, CGFloat, CGFloat)] = [(0.08, 0.10, 0.30), (0.95, 0.30, 0.36), (0.02, 0.62, 0.38), (0.90, 0.85, 0.32)]
    for (i, spot) in spots.enumerated() {
        let c = blobColors[(i + index) % blobColors.count]
        let center = CGPoint(x: spot.0 * CGFloat(W), y: flip(spot.1 * CGFloat(H), 0))
        let radius = spot.2 * CGFloat(W)
        let colors = [CGColor(srgbRed: c.0 / 255, green: c.1 / 255, blue: c.2 / 255, alpha: c.3),
                      CGColor(srgbRed: c.0 / 255, green: c.1 / 255, blue: c.2 / 255, alpha: 0)] as CFArray
        let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors, locations: [0, 1])!
        cg.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: [])
    }

    // 見出し（2行）と小さい文字。真ん中そろえ
    let titleSize = fit(lines, { titleFont(lang, $0) }, start: lang == "ja" ? 108 : 104, maxWidth: CGFloat(W) - 150)
    var y: CGFloat = 170 + (108 - titleSize) / 2
    for line in lines {
        let text = rich(line, font: titleFont(lang, titleSize), color: .white)
        let size = text.size()
        text.draw(at: NSPoint(x: (CGFloat(W) - size.width) / 2, y: flip(y, size.height)))
        y += titleSize * 1.38
    }
    if let sub {
        let subSize = fit([sub], { subFont(lang, $0) }, start: 54, maxWidth: CGFloat(W) - 130)
        let text = rich(sub, font: subFont(lang, subSize), color: subColor)
        let size = text.size()
        text.draw(at: NSPoint(x: (CGFloat(W) - size.width) / 2, y: flip(y + 8, size.height)))
        y += 90
    }

    // スマホ（枠・影・画面・ダイナミックアイランド）
    let screenW: CGFloat = 900
    let screenH = screenW * shot.size.height / shot.size.width
    let bezel: CGFloat = 24
    let phone = NSRect(x: (CGFloat(W) - screenW) / 2 - bezel, y: flip(y + 70, screenH + bezel * 2), width: screenW + bezel * 2, height: screenH + bezel * 2)
    let outer = NSBezierPath(roundedRect: phone, xRadius: 150, yRadius: 150)
    NSGraphicsContext.saveGraphicsState()
    let shadow = NSShadow()
    shadow.shadowColor = NSColor(srgbRed: 0, green: 30 / 255, blue: 80 / 255, alpha: 0.45)
    shadow.shadowBlurRadius = 40
    shadow.shadowOffset = NSSize(width: 12, height: -30)
    shadow.set()
    NSColor(srgbRed: 32 / 255, green: 33 / 255, blue: 36 / 255, alpha: 1).setFill()
    outer.fill()
    NSGraphicsContext.restoreGraphicsState()
    let screenRect = phone.insetBy(dx: bezel, dy: bezel)
    NSGraphicsContext.saveGraphicsState()
    NSBezierPath(roundedRect: screenRect, xRadius: 126, yRadius: 126).addClip()
    shot.draw(in: screenRect, from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
    NSGraphicsContext.restoreGraphicsState()
    let islandW = screenW * 0.286, islandH = screenW * 0.084
    NSColor.black.setFill()
    NSBezierPath(roundedRect: NSRect(x: screenRect.midX - islandW / 2, y: screenRect.maxY - screenW * 0.025 - islandH, width: islandW, height: islandH),
                 xRadius: islandH / 2, yRadius: islandH / 2).fill()

    NSGraphicsContext.restoreGraphicsState()
    // App Store は透明な部分のある画像を受け付けないので、アルファなしにする（RGBA で描いてから RGB だけに描き直す）。
    // 63枚を PNG にすると 76MB になるので、画質の高い JPEG にする（App Store は JPEG も受け付ける）
    let rgb = CGContext(data: nil, width: W, height: H, bitsPerComponent: 8, bytesPerRow: 0,
                        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    rgb.draw(rep.cgImage!, in: CGRect(x: 0, y: 0, width: W, height: H))
    let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: out) as CFURL, UTType.jpeg.identifier as CFString, 1, nil)!
    CGImageDestinationAddImage(destination, rgb.makeImage()!, [kCGImageDestinationLossyCompressionQuality: 0.92] as CFDictionary)
    CGImageDestinationFinalize(destination)
}

let root = FileManager.default.currentDirectoryPath
let inDir = "\(root)/build/store-screens"
for (lang, items) in captions.sorted(by: { $0.key < $1.key }) {
    let dir = "\(root)/docs/store/app-store/screenshots/\(lang)"
    try! FileManager.default.createDirectory(atPath: dir, withIntermediateDirectories: true)
    for (i, screen) in screens.enumerated() {
        compose(lang: lang, index: i + 1, screen: screen, lines: items[i].0, sub: items[i].1, inDir: inDir,
                out: String(format: "%@/%02d.jpg", dir, i + 1))
    }
    print("書き出し: \(lang)")
}
