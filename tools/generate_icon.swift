#!/usr/bin/env swift  // Renders MenteViva's app icon. Zero dependencies — AppKit only.  // Re-run after changing the design: swift tools/generate_icon.swift
//
// Design notes (Card Table, docs/design/2026-10-13-privacy-and-icon.html, option A):
// - One game card as Home deals it: white paper, a framed panel in Memory
//   Lane's ink, and the Memory Lane emblem drawn with the same shapes as
//   `Emblem` in GameCard.swift (64-point grid), on the table gradient.
// - The mark is memory cards, deliberately NOT a brain or medical glyph:
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

func rgb(_ hex: UInt32, _ alpha: CGFloat = 1) -> CGColor {
    CGColor(
        red: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}
let ink = rgb(0x23685F)  // GameID.memoryMatch.ink, light
let amber = rgb(0xF2B24C)  // Color.amber, light
let unit = CGFloat(side) / 100  // the design is drawn on a 100-unit square

// Work top-down like SwiftUI: y grows downward, positive angles turn clockwise.
ctx.translateBy(x: 0, y: CGFloat(side))
ctx.scaleBy(x: 1, y: -1)

// Background: the table gradient (Color.table), teal at the bottom left to
// amber at the top right, the same 32° as Home's table.
let table = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [rgb(0x2F7470), rgb(0x8DAF98), rgb(0xEDBB6C)] as CFArray,
    locations: [0, 0.52, 1])!
let angle = 32 * CGFloat.pi / 180
let reach = mid * (sin(angle) + cos(angle))
let direction = CGPoint(x: sin(angle), y: -cos(angle))
ctx.drawLinearGradient(
    table,
    start: CGPoint(x: mid - direction.x * reach, y: mid - direction.y * reach),
    end: CGPoint(x: mid + direction.x * reach, y: mid + direction.y * reach),
    options: [.drawsBeforeStartLocation, .drawsAfterEndLocation])

/// Rounded rectangle of `width` × `height` units centred on the origin.
func rounded(_ width: CGFloat, _ height: CGFloat, _ radius: CGFloat) -> CGPath {
    CGPath(
        roundedRect: CGRect(x: -width * unit / 2, y: -height * unit / 2, width: width * unit, height: height * unit),
        cornerWidth: radius * unit, cornerHeight: radius * unit, transform: nil)
}

// MARK: - The card, tilted a little like a card just dealt

ctx.translateBy(x: mid, y: 52 * unit)
ctx.rotate(by: -6 * .pi / 180)

// White paper with a soft shadow on the table.
ctx.saveGState()
// Shadow offsets ignore the flip above, so "down" is negative here.
ctx.setShadow(offset: CGSize(width: 0, height: -2.2 * unit), blur: 4.8 * unit, color: rgb(0x0B2422, 0.32))
ctx.addPath(rounded(52, 70, 9))
ctx.setFillColor(rgb(0xFFFFFF))
ctx.fillPath()
ctx.restoreGState()

// The framed panel: the ink at 12% behind a 3-unit ink frame, as on GameCard.
ctx.addPath(rounded(45, 63, 6.5))
ctx.setFillColor(ink.copy(alpha: 0.12)!)
ctx.fillPath()
ctx.addPath(rounded(42, 60, 5))
ctx.setStrokeColor(ink)
ctx.setLineWidth(3 * unit)
ctx.strokePath()

// MARK: - Memory Lane's emblem, on its 64-point grid, centred in the panel

let grid = 44 * unit / 64
ctx.translateBy(x: -32 * grid, y: -31 * grid)

/// Emblem's 28 × 38 card at (x, y) on the grid, turned by `degrees`.
func emblemCard(x: CGFloat, y: CGFloat, degrees: CGFloat) -> CGPath {
    let rect = CGRect(x: x * grid, y: y * grid, width: 28 * grid, height: 38 * grid)
    var turn = CGAffineTransform(translationX: rect.midX, y: rect.midY)
        .rotated(by: degrees * .pi / 180)
        .translatedBy(x: -rect.midX, y: -rect.midY)
    return CGPath(roundedRect: rect, cornerWidth: 5 * grid, cornerHeight: 5 * grid, transform: &turn)
}
ctx.addPath(emblemCard(x: 9, y: 12, degrees: -12))
ctx.setFillColor(ink.copy(alpha: 0.35)!)
ctx.fillPath()
ctx.addPath(emblemCard(x: 25, y: 13, degrees: 9))
ctx.setFillColor(ink)
ctx.fillPath()
ctx.setFillColor(amber)
ctx.fillEllipse(in: CGRect(x: (39 - 5.5) * grid, y: (32 - 5.5) * grid, width: 11 * grid, height: 11 * grid))

NSGraphicsContext.restoreGraphicsState()

guard let png = rep.representation(using: .png, properties: [:]) else {
    fatalError("could not encode PNG")
}
let out = iconDir.appendingPathComponent("icon-1024.png")
try png.write(to: out)
print("Wrote \(out.path) — \(rep.pixelsWide)×\(rep.pixelsHigh), \(png.count) bytes")
