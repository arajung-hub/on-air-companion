import AppKit

guard CommandLine.arguments.count == 2 else {
    fputs("usage: generate-app-icon.swift OUTPUT.png\n", stderr)
    exit(EXIT_FAILURE)
}

let side = 1024
guard let bitmap = NSBitmapImageRep(
    bitmapDataPlanes: nil,
    pixelsWide: side,
    pixelsHigh: side,
    bitsPerSample: 8,
    samplesPerPixel: 4,
    hasAlpha: true,
    isPlanar: false,
    colorSpaceName: .deviceRGB,
    bytesPerRow: 0,
    bitsPerPixel: 0
), let context = NSGraphicsContext(bitmapImageRep: bitmap) else {
    exit(EXIT_FAILURE)
}

bitmap.size = NSSize(width: side, height: side)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = context
context.imageInterpolation = .high

NSColor.clear.setFill()
NSBezierPath(rect: NSRect(x: 0, y: 0, width: side, height: side)).fill()

let tileRect = NSRect(x: 72, y: 72, width: 880, height: 880)
let tile = NSBezierPath(roundedRect: tileRect, xRadius: 212, yRadius: 212)
context.cgContext.setShadow(
    offset: CGSize(width: 0, height: -14),
    blur: 28,
    color: NSColor.black.withAlphaComponent(0.16).cgColor
)
NSGradient(
    starting: NSColor(red: 0.96, green: 0.94, blue: 0.90, alpha: 1),
    ending: NSColor(red: 1.0, green: 0.99, blue: 0.97, alpha: 1)
)?.draw(in: tile, angle: 90)
context.cgContext.setShadow(offset: .zero, blur: 0)

NSColor.white.withAlphaComponent(0.66).setStroke()
tile.lineWidth = 4
tile.stroke()

let micColor = NSColor(red: 1.0, green: 0.47, blue: 0.39, alpha: 1)
micColor.setFill()
NSBezierPath(
    roundedRect: NSRect(x: 260, y: 468, width: 100, height: 204),
    xRadius: 50,
    yRadius: 50
).fill()

let micArc = NSBezierPath()
micArc.lineWidth = 28
micArc.lineCapStyle = .round
micArc.appendArc(
    withCenter: NSPoint(x: 310, y: 508),
    radius: 98,
    startAngle: 180,
    endAngle: 360,
    clockwise: false
)
micColor.setStroke()
micArc.stroke()

let micStem = NSBezierPath()
micStem.move(to: NSPoint(x: 310, y: 410))
micStem.line(to: NSPoint(x: 310, y: 354))
micStem.move(to: NSPoint(x: 264, y: 354))
micStem.line(to: NSPoint(x: 356, y: 354))
micStem.lineWidth = 28
micStem.lineCapStyle = .round
micStem.stroke()

let cameraColor = NSColor(red: 0.44, green: 0.37, blue: 0.90, alpha: 1)
cameraColor.setFill()
NSBezierPath(
    roundedRect: NSRect(x: 496, y: 434, width: 202, height: 154),
    xRadius: 42,
    yRadius: 42
).fill()

let lens = NSBezierPath()
lens.move(to: NSPoint(x: 710, y: 545))
lens.line(to: NSPoint(x: 781, y: 588))
lens.curve(
    to: NSPoint(x: 806, y: 575),
    controlPoint1: NSPoint(x: 794, y: 596),
    controlPoint2: NSPoint(x: 806, y: 588)
)
lens.line(to: NSPoint(x: 806, y: 447))
lens.curve(
    to: NSPoint(x: 781, y: 434),
    controlPoint1: NSPoint(x: 806, y: 434),
    controlPoint2: NSPoint(x: 794, y: 426)
)
lens.line(to: NSPoint(x: 710, y: 477))
lens.close()
lens.fill()

NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else {
    exit(EXIT_FAILURE)
}
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
