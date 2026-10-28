#!/usr/bin/env swift  // Renders MenteViva's app icon. Zero dependencies — AppKit only.
// Re-run after changing the design: swift tools/generate_icon.swift
//
// Design notes (retro card icon, #337, docs/design/icon-studies.md study A):
// - One dealt card: cream paper, espresso ink outline, a jade panel and one
//   mustard disc on dark jade. Flat fills only, so it reads at 40 px.
// - Colours are the shared retro tokens (docs/design/art-style.md).
// - The mark is a playing card, deliberately NOT a brain or medical glyph:
//   research-2026-09.md §1 caps our positioning at "fun mental exercise".
// - Full-bleed, opaque, square: iOS rounds the corners; no alpha, no shadow.
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
        srgbRed: CGFloat((hex >> 16) & 0xFF) / 255, green: CGFloat((hex >> 8) & 0xFF) / 255,
        blue: CGFloat(hex & 0xFF) / 255, alpha: alpha)
}
let cream = rgb(0xFFF1D0)
let espresso = rgb(0x2B2118)
let jade = rgb(0x246456)
let mustard = rgb(0xE7AC45)
let ground = rgb(0x143F36)  // jade, darkened so the cream card stands off it
let unit = CGFloat(side) / 100  // the design is drawn on a 100-unit square

// Work top-down like SwiftUI: y grows downward, positive angles turn clockwise.
ctx.translateBy(x: 0, y: CGFloat(side))
ctx.scaleBy(x: 1, y: -1)

ctx.setFillColor(ground)
ctx.fill(CGRect(x: 0, y: 0, width: side, height: side))

/// Rounded rectangle of `width` × `height` units centred on the origin.
func rounded(_ width: CGFloat, _ height: CGFloat, _ radius: CGFloat) -> CGPath {
    CGPath(
        roundedRect: CGRect(x: -width * unit / 2, y: -height * unit / 2, width: width * unit, height: height * unit),
        cornerWidth: radius * unit, cornerHeight: radius * unit, transform: nil)
}

/// Fills `path` then draws a rounded `ink` outline of `line` units over its edge.
func inked(_ path: CGPath, fill: CGColor, line: CGFloat) {
    ctx.addPath(path)
    ctx.setFillColor(fill)
    ctx.fillPath()
    ctx.addPath(path)
    ctx.setStrokeColor(espresso)
    ctx.setLineWidth(line * unit)
    ctx.setLineJoin(.round)
    ctx.strokePath()
}

// The card, tilted a little like a card just dealt.
ctx.translateBy(x: mid, y: 50 * unit)
ctx.rotate(by: -6 * .pi / 180)
inked(rounded(54, 71, 9), fill: cream, line: 2.6)
// The jade panel has no outline of its own: jade on cream already separates, and a
// second line would blur at 40 px.
ctx.addPath(rounded(41, 58, 6))
ctx.setFillColor(jade)
ctx.fillPath()
let disc = CGRect(x: -16 * unit, y: -16 * unit, width: 32 * unit, height: 32 * unit)
ctx.addEllipse(in: disc)
ctx.setFillColor(mustard)
ctx.fillPath()
ctx.addEllipse(in: disc)
ctx.setStrokeColor(espresso)
ctx.setLineWidth(2.4 * unit)
ctx.strokePath()

NSGraphicsContext.restoreGraphicsState()

// Re-draw into an alpha-less buffer so the PNG is truly opaque: the App Store
// rejects an icon with an alpha channel, even a fully opaque one.
guard
    let rendered = rep.cgImage,
    let flat = CGContext(
        data: nil, width: side, height: side, bitsPerComponent: 8, bytesPerRow: 0,
        space: CGColorSpace(name: CGColorSpace.sRGB)!, bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)
else {
    fatalError("could not create opaque context")
}
flat.draw(rendered, in: CGRect(x: 0, y: 0, width: side, height: side))
let out = iconDir.appendingPathComponent("icon-1024.png")
guard let image = flat.makeImage(),
    let dest = CGImageDestinationCreateWithURL(out as CFURL, "public.png" as CFString, 1, nil)
else {
    fatalError("could not encode PNG")
}
CGImageDestinationAddImage(dest, image, nil)
guard CGImageDestinationFinalize(dest) else { fatalError("could not write PNG") }
print("Wrote \(out.path) — \(side)×\(side)")
