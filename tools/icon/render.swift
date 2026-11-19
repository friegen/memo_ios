// SVG を PNG に描く（macOS の AppKit を使う）。
// 使い方: swift render.swift <入力.svg> <出力.png> <ピクセル数> [noalpha]
//   noalpha: 透明の情報（アルファ）を持たない PNG にする（App Store のアイコンはアルファを持てないため）
import AppKit
import ImageIO
import UniformTypeIdentifiers

let args = CommandLine.arguments
let input = URL(fileURLWithPath: args[1])
let output = URL(fileURLWithPath: args[2])
let size = Int(args[3])!
let opaque = args.count > 4 && args[4] == "noalpha"

guard let image = NSImage(contentsOf: input) else {
    print("SVG を読めない: \(args[1])")
    exit(1)
}

// まずアルファ付きで描く（AppKit はアルファなしの画像に直接は描けず、真っ黒になるため）
let rep = NSBitmapImageRep(
    bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8,
    samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
    colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
image.draw(in: NSRect(x: 0, y: 0, width: size, height: size))
NSGraphicsContext.restoreGraphicsState()

var cgImage = rep.cgImage!
if opaque {
    // アルファを外す（RGB だけの画像に描き直す）
    let context = CGContext(
        data: nil, width: size, height: size, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
    cgImage = context.makeImage()!
}
let destination = CGImageDestinationCreateWithURL(output as CFURL, UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, cgImage, nil)
guard CGImageDestinationFinalize(destination) else {
    print("PNG を書けない: \(args[2])")
    exit(1)
}
