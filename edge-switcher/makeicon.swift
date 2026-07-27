// makeicon — render a coloured rounded-square Dock icon with a letter.
//
//   makeicon <#rrggbb> <letter> <out.iconset>
//
// CoreGraphics + CoreText only, so it works headless (no window server needed).

import CoreGraphics
import CoreText
import Foundation
import ImageIO
import UniformTypeIdentifiers

let args = Array(CommandLine.arguments.dropFirst())
guard args.count == 3 else {
    print("usage: makeicon <#rrggbb> <letter> <out.iconset>")
    exit(1)
}
let hex = args[0].hasPrefix("#") ? String(args[0].dropFirst()) : args[0]
let letter = String(args[1].prefix(1)).uppercased()
let outDir = args[2]

let rgb = UInt32(hex, radix: 16) ?? 0x0F6CBD
let r = CGFloat((rgb >> 16) & 0xFF) / 255
let g = CGFloat((rgb >> 8) & 0xFF) / 255
let b = CGFloat(rgb & 0xFF) / 255

// Luminance decides black vs white glyph so bright colours stay legible.
let luminance = 0.2126 * r + 0.7152 * g + 0.0722 * b
let ink: CGFloat = luminance > 0.6 ? 0 : 1

func render(_ size: Int) -> CGImage? {
    let s = CGFloat(size)
    guard let ctx = CGContext(data: nil, width: size, height: size, bitsPerComponent: 8,
                              bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                              bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
    else { return nil }

    // macOS icons sit in a ~10% margin rather than filling the tile edge to edge.
    let inset = s * 0.10
    let rect = CGRect(x: inset, y: inset, width: s - inset * 2, height: s - inset * 2)
    let path = CGPath(roundedRect: rect, cornerWidth: rect.width * 0.235,
                      cornerHeight: rect.width * 0.235, transform: nil)

    ctx.setFillColor(CGColor(red: r, green: g, blue: b, alpha: 1))
    ctx.addPath(path)
    ctx.fillPath()

    let font = CTFontCreateWithName("Helvetica-Bold" as CFString, s * 0.46, nil)
    let attrs: [CFString: Any] = [
        kCTFontAttributeName: font,
        kCTForegroundColorAttributeName: CGColor(red: ink, green: ink, blue: ink, alpha: 1),
    ]
    let attributed = CFAttributedStringCreate(nil, letter as CFString, attrs as CFDictionary)!
    let line = CTLineCreateWithAttributedString(attributed)
    let bounds = CTLineGetBoundsWithOptions(line, .useOpticalBounds)
    ctx.textPosition = CGPoint(x: (s - bounds.width) / 2 - bounds.minX,
                               y: (s - bounds.height) / 2 - bounds.minY)
    CTLineDraw(line, ctx)

    return ctx.makeImage()
}

try? FileManager.default.createDirectory(atPath: outDir,
                                         withIntermediateDirectories: true)

// The set iconutil expects.
let variants: [(name: String, px: Int)] = [
    ("icon_16x16", 16), ("icon_16x16@2x", 32),
    ("icon_32x32", 32), ("icon_32x32@2x", 64),
    ("icon_128x128", 128), ("icon_128x128@2x", 256),
    ("icon_256x256", 256), ("icon_256x256@2x", 512),
    ("icon_512x512", 512), ("icon_512x512@2x", 1024),
]

for v in variants {
    guard let img = render(v.px) else { continue }
    let url = URL(fileURLWithPath: "\(outDir)/\(v.name).png") as CFURL
    guard let dest = CGImageDestinationCreateWithURL(url, UTType.png.identifier as CFString, 1, nil)
    else { continue }
    CGImageDestinationAddImage(dest, img, nil)
    CGImageDestinationFinalize(dest)
}
