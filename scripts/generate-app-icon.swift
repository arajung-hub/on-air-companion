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
    offset: CGSize(width: 0, height: -24),
    blur: 42,
    color: NSColor.black.withAlphaComponent(0.22).cgColor
)
NSGradient(
    starting: NSColor(red: 1.0, green: 0.965, blue: 0.925, alpha: 1),
    ending: NSColor(red: 0.91, green: 0.94, blue: 0.98, alpha: 1)
)?.draw(in: tile, angle: 90)
context.cgContext.setShadow(offset: .zero, blur: 0)

NSColor.white.withAlphaComponent(0.66).setStroke()
tile.lineWidth = 4
tile.stroke()

let capsuleRect = NSRect(x: 168, y: 360, width: 688, height: 304)
let capsule = NSBezierPath(
    roundedRect: capsuleRect,
    xRadius: capsuleRect.height / 2,
    yRadius: capsuleRect.height / 2
)
context.cgContext.setShadow(
    offset: CGSize(width: 0, height: -16),
    blur: 28,
    color: NSColor.black.withAlphaComponent(0.28).cgColor
)
NSColor(red: 0.115, green: 0.12, blue: 0.15, alpha: 1).setFill()
capsule.fill()
context.cgContext.setShadow(offset: .zero, blur: 0)

NSColor.white.withAlphaComponent(0.14).setStroke()
capsule.lineWidth = 5
capsule.stroke()

let recordingCenter = NSPoint(x: 278, y: 512)
context.cgContext.setShadow(
    offset: .zero,
    blur: 28,
    color: NSColor(red: 0.96, green: 0.2, blue: 0.25, alpha: 0.82).cgColor
)
NSColor(red: 0.96, green: 0.21, blue: 0.27, alpha: 1).setFill()
NSBezierPath(
    ovalIn: NSRect(
        x: recordingCenter.x - 38,
        y: recordingCenter.y - 38,
        width: 76,
        height: 76
    )
).fill()
context.cgContext.setShadow(offset: .zero, blur: 0)

let micColor = NSColor(red: 1.0, green: 0.47, blue: 0.39, alpha: 1)
micColor.setFill()
NSBezierPath(
    roundedRect: NSRect(x: 406, y: 470, width: 68, height: 132),
    xRadius: 34,
    yRadius: 34
).fill()

let micArc = NSBezierPath()
micArc.lineWidth = 22
micArc.lineCapStyle = .round
micArc.appendArc(
    withCenter: NSPoint(x: 440, y: 507),
    radius: 64,
    startAngle: 198,
    endAngle: 342,
    clockwise: false
)
micColor.setStroke()
micArc.stroke()

let micStem = NSBezierPath()
micStem.move(to: NSPoint(x: 440, y: 441))
micStem.line(to: NSPoint(x: 440, y: 414))
micStem.lineWidth = 22
micStem.lineCapStyle = .round
micStem.stroke()

let cameraColor = NSColor(red: 0.49, green: 0.43, blue: 0.96, alpha: 1)
cameraColor.setFill()
NSBezierPath(
    roundedRect: NSRect(x: 566, y: 456, width: 132, height: 112),
    xRadius: 30,
    yRadius: 30
).fill()

let lens = NSBezierPath()
lens.move(to: NSPoint(x: 705, y: 530))
lens.line(to: NSPoint(x: 772, y: 574))
lens.curve(
    to: NSPoint(x: 786, y: 553),
    controlPoint1: NSPoint(x: 780, y: 580),
    controlPoint2: NSPoint(x: 786, y: 568)
)
lens.line(to: NSPoint(x: 786, y: 471))
lens.curve(
    to: NSPoint(x: 772, y: 450),
    controlPoint1: NSPoint(x: 786, y: 456),
    controlPoint2: NSPoint(x: 780, y: 444)
)
lens.line(to: NSPoint(x: 705, y: 494))
lens.close()
lens.fill()

NSGraphicsContext.restoreGraphicsState()

guard let data = bitmap.representation(using: .png, properties: [:]) else {
    exit(EXIT_FAILURE)
}
try data.write(to: URL(fileURLWithPath: CommandLine.arguments[1]))
