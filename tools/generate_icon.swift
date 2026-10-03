#!/usr/bin/env swift  // Renders MenteViva's app icon. Zero dependencies — AppKit only.
// Re-run after changing the design: swift tools/generate_icon.swift
//
// Design notes:
// - Warm sunrise gradient (calm, not clinical).
// - The mark is two memory cards, deliberately NOT a brain or medical glyph:
//   research-2026-09.md §1 caps our positioning at "fun mental exercise".
// - Drawn into an explicit 1024×1024 pixel buffer. NSImage + tiffRepresentation
//   doubles to 2048 on a Retina Mac, and Apple's single-size app icon must be
//   exactly 1024×1024 — actool rejects anything else.
import AppKit

let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
let iconDir = root.appendingPathComponent("MenteViva/Assets.xcassets/AppIcon.appiconset")
try FileManager.default.createDirectory(at: iconDir, withIntermediateDirectories: true)

let side = 1024
let mid = CGFloat(side) / 2

guard
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: side, pixelsHigh: side,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true,
        isPlanar: false, colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0),
    let gctx = NSGraphicsContext(bitmapImageRep: rep)
else {
    fatalError("could not create bitmap context")
}

NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = gctx
let ctx = gctx.cgContext

// Background: deep teal at the bottom, warm amber at the top.
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.13, green: 0.42, blue: 0.45, alpha: 1),
    NSColor(calibratedRed: 0.98, green: 0.72, blue: 0.35, alpha: 1),
])!
gradient.draw(in: NSRect(x: 0, y: 0, width: side, height: side), angle: 65)

// Soft bloom so the mark stays readable at 40pt on a home screen.
let bloom = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.26),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0),
    ] as CFArray,
    locations: [0, 1])!
ctx.drawRadialGradient(
    bloom,
    startCenter: CGPoint(x: mid, y: mid), startRadius: 0,
    endCenter: CGPoint(x: mid, y: mid), endRadius: CGFloat(side) * 0.44,
    options: [])

// MARK: - Mark: two overlapping memory cards

/// Rounded rectangle centred on `center`, rotated clockwise by `degrees`.
func cardPath(
    center: CGPoint, width: CGFloat, height: CGFloat,
    cornerRadius: CGFloat, degrees: CGFloat
) -> CGPath {
    let rect = CGRect(x: -width / 2, y: -height / 2, width: width, height: height)
    let path = CGPath(
        roundedRect: rect, cornerWidth: cornerRadius,
        cornerHeight: cornerRadius, transform: nil)
    var transform = CGAffineTransform(translationX: center.x, y: center.y)
        .rotated(by: degrees * .pi / 180)
    return path.copy(using: &transform)!
}

let cardWidth = CGFloat(side) * 0.40
let cardHeight = CGFloat(side) * 0.50
let cornerRadius = CGFloat(side) * 0.075
let frontCenter = CGPoint(x: mid + CGFloat(side) * 0.085, y: mid)

// Back card: translucent cream, tilted left.
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -CGFloat(side) * 0.012),
    blur: CGFloat(side) * 0.03,
    color: CGColor(red: 0, green: 0.15, blue: 0.15, alpha: 0.28))
ctx.addPath(
    cardPath(
        center: CGPoint(x: mid - CGFloat(side) * 0.075, y: mid),
        width: cardWidth, height: cardHeight,
        cornerRadius: cornerRadius, degrees: -9))
ctx.setFillColor(CGColor(red: 1, green: 0.96, blue: 0.88, alpha: 0.72))
ctx.fillPath()
ctx.restoreGState()

// Front card: solid cream, tilted right.
ctx.saveGState()
ctx.setShadow(
    offset: CGSize(width: 0, height: -CGFloat(side) * 0.014),
    blur: CGFloat(side) * 0.035,
    color: CGColor(red: 0, green: 0.15, blue: 0.15, alpha: 0.30))
ctx.addPath(
    cardPath(
        center: frontCenter, width: cardWidth, height: cardHeight,
        cornerRadius: cornerRadius, degrees: 8))
ctx.setFillColor(CGColor(red: 1, green: 0.99, blue: 0.95, alpha: 1))
ctx.fillPath()
ctx.restoreGState()

// Card face: a warm dot, centred on the front card (unrotated, reads cleaner).
ctx.saveGState()
ctx.setFillColor(CGColor(red: 0.95, green: 0.62, blue: 0.26, alpha: 1))
let dotR = CGFloat(side) * 0.055
ctx.fillEllipse(
    in: CGRect(
        x: frontCenter.x - dotR, y: frontCenter.y - dotR,
        width: dotR * 2, height: dotR * 2))
ctx.restoreGState()

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not encode PNG")
}
let out = iconDir.appendingPathComponent("icon-1024.png")
try png.write(to: out)
print("Wrote \(out.path) — \(rep.pixelsWide)×\(rep.pixelsHigh), \(png.count) bytes")
