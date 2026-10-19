//
//  make_icon.swift
//  MacToys
//
//  Erzeugt ein einfaches App-Icon (Quadrat mit Hammer + Akzentblau) als PNG.
//  Aufruf: swift make_icon.swift Resources/icon-source.png
//  build.sh wandelt das dann via sips/iconutil in .icns um.
//

import AppKit
import CoreGraphics
import Foundation

guard CommandLine.arguments.count >= 2 else {
    FileHandle.standardError.write("Nutzung: make_icon.swift <output.png>\n".data(using: .utf8)!)
    exit(1)
}
let outPath = CommandLine.arguments[1]

let size = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let ctx = CGContext(
    data: nil, width: size, height: size,
    bitsPerComponent: 8, bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else { exit(2) }

// Hintergrund: gerundetes Quadrat, MacToys-Blau (#0A84FF).
let rect = CGRect(x: 0, y: 0, width: size, height: size)
let radius: CGFloat = CGFloat(size) * 0.22
let bgPath = CGPath(roundedRect: rect, cornerWidth: radius, cornerHeight: radius, transform: nil)
ctx.addPath(bgPath)
ctx.setFillColor(CGColor(red: 0.039, green: 0.518, blue: 1.0, alpha: 1.0))
ctx.fillPath()

// Hammer-Glyphe als Text (SF), weiß, zentriert.
let attr: [NSAttributedString.Key: Any] = [
    .font: NSFont.systemFont(ofSize: CGFloat(size) * 0.62, weight: .black),
    .foregroundColor: NSColor.white
]
let str = NSAttributedString(string: "🔨", attributes: attr)
let line = CTLineCreateWithAttributedString(str)
let bounds = CTLineGetBoundsWithOptions(line, [])
let textOriginX = (CGFloat(size) - bounds.width) / 2 - bounds.origin.x
let textOriginY = (CGFloat(size) - bounds.height) / 2 - bounds.origin.y
ctx.textPosition = CGPoint(x: textOriginX, y: textOriginY)
CTLineDraw(line, ctx)

guard let img = ctx.makeImage() else { exit(3) }
let dest = CGImageDestinationCreateWithURL(URL(fileURLWithPath: outPath) as CFURL,
                                           "public.png" as CFString, 1, nil)!
CGImageDestinationAddImage(dest, img, nil)
CGImageDestinationFinalize(dest)
print("✅ \(outPath)")
