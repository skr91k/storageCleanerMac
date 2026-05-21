#!/usr/bin/env swift
// Generates a 1024x1024 app icon PNG for Storage Cleaner
import CoreGraphics
import ImageIO
import Foundation

let S: CGFloat = 1024
let ctx = CGContext(
    data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
    bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
)!

// ── Helpers ───────────────────────────────────────────────────────────────────
func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint { .init(x: x * S, y: y * S) }
func r(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat) -> CGRect {
    .init(x: x * S, y: y * S, width: w * S, height: h * S)
}

// ── Background: deep blue → indigo gradient ───────────────────────────────────
let bgPath = CGMutablePath()
bgPath.addRoundedRect(in: r(0,0,1,1), cornerWidth: S*0.22, cornerHeight: S*0.22)
ctx.saveGState()
ctx.addPath(bgPath); ctx.clip()
let grad = CGGradient(
    colorsSpace: CGColorSpaceCreateDeviceRGB(),
    colors: [
        CGColor(red: 0.10, green: 0.28, blue: 0.90, alpha: 1),
        CGColor(red: 0.38, green: 0.14, blue: 0.82, alpha: 1)
    ] as CFArray,
    locations: [0, 1]
)!
ctx.drawLinearGradient(grad, start: p(0.1, 1.0), end: p(0.9, 0.0), options: [])
ctx.restoreGState()

// ── Disk body ─────────────────────────────────────────────────────────────────
let diskRect = r(0.16, 0.30, 0.68, 0.40)
ctx.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 0.97))
let diskPath = CGMutablePath()
diskPath.addRoundedRect(in: diskRect, cornerWidth: S*0.055, cornerHeight: S*0.055)
ctx.addPath(diskPath); ctx.fillPath()

// Disk arm
ctx.setFillColor(CGColor(red: 0.75, green: 0.78, blue: 0.88, alpha: 1))
let armRect = r(0.46, 0.355, 0.28, 0.055)
let armPath = CGMutablePath()
armPath.addRoundedRect(in: armRect, cornerWidth: S*0.025, cornerHeight: S*0.025)
ctx.addPath(armPath); ctx.fillPath()

// Platter (circle)
let platCX = S * 0.355
let platCY = S * 0.500
let platR  = S * 0.115
ctx.setFillColor(CGColor(red: 0.86, green: 0.88, blue: 0.95, alpha: 1))
ctx.fillEllipse(in: .init(x: platCX - platR, y: platCY - platR,
                           width: platR*2, height: platR*2))
// Platter hub
ctx.setFillColor(CGColor(red: 0.30, green: 0.22, blue: 0.78, alpha: 1))
let hubR = platR * 0.38
ctx.fillEllipse(in: .init(x: platCX - hubR, y: platCY - hubR,
                           width: hubR*2, height: hubR*2))

// LED
ctx.setFillColor(CGColor(red: 0.20, green: 0.92, blue: 0.45, alpha: 1))
let ledR = S * 0.024
ctx.fillEllipse(in: .init(x: S*0.745, y: S*0.460, width: ledR*2, height: ledR*2))

// ── Sparkle (bottom-right quadrant) ──────────────────────────────────────────
func drawSparkle(_ ctx: CGContext, cx: CGFloat, cy: CGFloat, r: CGFloat, color: CGColor) {
    ctx.setFillColor(color)
    let inner = r * 0.30
    let path = CGMutablePath()
    for i in 0..<8 {
        let a = CGFloat(i) * .pi / 4 - .pi / 8
        let rad = i % 2 == 0 ? r : inner
        let pt = CGPoint(x: cx + cos(a)*rad, y: cy + sin(a)*rad)
        i == 0 ? path.move(to: pt) : path.addLine(to: pt)
    }
    path.closeSubpath()
    ctx.addPath(path); ctx.fillPath()
}

drawSparkle(ctx, cx: S*0.685, cy: S*0.245, r: S*0.085,
            color: CGColor(red: 1.0, green: 0.88, blue: 0.25, alpha: 1))
drawSparkle(ctx, cx: S*0.770, cy: S*0.310, r: S*0.038,
            color: CGColor(red: 1.0, green: 0.95, blue: 0.55, alpha: 0.9))
drawSparkle(ctx, cx: S*0.630, cy: S*0.195, r: S*0.022,
            color: CGColor(red: 1.0, green: 0.95, blue: 0.55, alpha: 0.8))

// ── Save ──────────────────────────────────────────────────────────────────────
let outPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : ".build/icon_1024.png"

let dest = CGImageDestinationCreateWithURL(
    URL(fileURLWithPath: outPath) as CFURL, "public.png" as CFString, 1, nil
)!
CGImageDestinationAddImage(dest, ctx.makeImage()!, nil)
CGImageDestinationFinalize(dest)
print("Icon → \(outPath)")
