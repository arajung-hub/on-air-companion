import AppKit
import ApplicationServices
import QuartzCore

struct DeviceState: Equatable {
    let microphoneOn: Bool
    let cameraOn: Bool
    let meetingActive: Bool

    static let quiet = DeviceState(
        microphoneOn: false,
        cameraOn: false,
        meetingActive: true
    )
}

enum IndicatorKind: String, CaseIterable, Hashable {
    case quiet
    case microphone
    case camera
    case live
    case permissionNeeded

    init(state: DeviceState) {
        if state.microphoneOn && state.cameraOn {
            self = .live
        } else if state.microphoneOn {
            self = .microphone
        } else if state.cameraOn {
            self = .camera
        } else {
            self = .quiet
        }
    }

    var filename: String {
        switch self {
        case .quiet: return "quiet"
        case .microphone: return "microphone-on"
        case .camera: return "camera-on"
        case .live: return "live"
        case .permissionNeeded: return "permission-needed"
        }
    }

    var isUrgent: Bool {
        self == .microphone || self == .camera || self == .live
    }
}

enum MonitorObservation: Equatable {
    case noMeeting
    case permissionNeeded
    case state(DeviceState)
}

enum SourceMode: Equatable {
    case zoom
    case demo(DeviceState)
}

enum VisualStyle: String, Equatable {
    case basic
    case animal

    var displayName: String {
        switch self {
        case .basic: return "기본형"
        case .animal: return "동물형"
        }
    }

    var panelSize: NSSize {
        switch self {
        case .basic: return NSSize(width: 204, height: 50)
        case .animal: return NSSize(width: 132, height: 88)
        }
    }
}

enum BasicVariant: String, CaseIterable {
    case capsule
    case dualTiles = "dual-tiles"
    case iconBar = "icon-bar"
    case statusRing = "status-ring"

    var displayName: String {
        switch self {
        case .capsule: return "상태 캡슐"
        case .dualTiles: return "듀얼 타일"
        case .iconBar: return "아이콘 바"
        case .statusRing: return "상태 링"
        }
    }

    var detail: String {
        switch self {
        case .capsule: return "상태를 문구로 또렷하게"
        case .dualTiles: return "마이크와 카메라를 따로"
        case .iconBar: return "작은 공간에 아이콘만"
        case .statusRing: return "둥근 링으로 가볍게"
        }
    }

    var panelSize: NSSize {
        switch self {
        case .capsule: return NSSize(width: 204, height: 50)
        case .dualTiles: return NSSize(width: 162, height: 66)
        case .iconBar: return NSSize(width: 112, height: 46)
        case .statusRing: return NSSize(width: 86, height: 86)
        }
    }
}

extension IndicatorKind {
    var microphoneOn: Bool { self == .microphone || self == .live }
    var cameraOn: Bool { self == .camera || self == .live }

    var displayName: String {
        switch self {
        case .quiet: return "모두 꺼짐"
        case .microphone: return "마이크만 켜짐"
        case .camera: return "카메라만 켜짐"
        case .live: return "둘 다 켜짐"
        case .permissionNeeded: return "접근성 권한 필요"
        }
    }
}

struct CharacterProfile: Hashable {
    let id: String
    let displayName: String
    let assetName: String
    let scale: CGFloat

    static let all: [CharacterProfile] = [
        CharacterProfile(id: "capybara", displayName: "카피바라", assetName: "capybara", scale: 0.96),
        CharacterProfile(id: "hamster", displayName: "햄스터", assetName: "hamster", scale: 0.96),
        CharacterProfile(id: "maltese", displayName: "말티즈", assetName: "maltese", scale: 1.04),
        CharacterProfile(id: "teal-dragon", displayName: "청록 용공룡", assetName: "teal-dragon", scale: 1.01),
        CharacterProfile(id: "siamese-cat", displayName: "샴고양이", assetName: "siamese-cat", scale: 1.00),
        CharacterProfile(id: "fox", displayName: "여우", assetName: "fox", scale: 0.98),
        CharacterProfile(id: "lop-rabbit", displayName: "롭이어 토끼", assetName: "lop-rabbit", scale: 1.02),
        CharacterProfile(id: "duck", displayName: "오리", assetName: "duck", scale: 1.03),
        CharacterProfile(id: "axolotl", displayName: "아홀로틀", assetName: "axolotl", scale: 0.97),
        CharacterProfile(id: "penguin", displayName: "펭귄", assetName: "penguin", scale: 1.02),
        CharacterProfile(id: "turtle", displayName: "거북이", assetName: "turtle", scale: 0.96),
        CharacterProfile(id: "seal", displayName: "물범", assetName: "seal", scale: 0.97),
    ]

    static var defaultCharacter: CharacterProfile { all[0] }

    static func character(withID id: String?) -> CharacterProfile? {
        guard let id else { return nil }
        return all.first { $0.id == id }
    }
}

extension NSColor {
    convenience init(hex: UInt32, alpha: CGFloat = 1) {
        let red = CGFloat((hex >> 16) & 0xff) / 255
        let green = CGFloat((hex >> 8) & 0xff) / 255
        let blue = CGFloat(hex & 0xff) / 255
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}

private func loadCharacterImage(
    _ character: CharacterProfile,
    useActiveExpression: Bool = false
) -> NSImage? {
    let subdirectory = useActiveExpression ? "CharactersActive" : "Characters"
    guard let url = Bundle.main.url(
        forResource: character.assetName,
        withExtension: "png",
        subdirectory: subdirectory
    ) else {
        if useActiveExpression {
            return loadCharacterImage(character)
        }
        return nil
    }
    return NSImage(contentsOf: url)
}

private func aspectFit(imageSize: NSSize, in rect: NSRect) -> NSRect {
    guard imageSize.width > 0, imageSize.height > 0 else { return rect }
    let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
    let size = NSSize(width: imageSize.width * scale, height: imageSize.height * scale)
    return NSRect(
        x: rect.midX - size.width / 2,
        y: rect.midY - size.height / 2,
        width: size.width,
        height: size.height
    )
}

final class IndicatorView: NSView {
    private(set) var kind: IndicatorKind = .quiet
    private(set) var character: CharacterProfile
    private var animationTimer: Timer?
    private var animationStart = Date()
    private var cachedImages: [String: NSImage] = [:]

    override var isFlipped: Bool { true }

    init(frame frameRect: NSRect, character: CharacterProfile) {
        self.character = character
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        startAnimation()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        animationTimer?.invalidate()
    }

    func apply(_ nextKind: IndicatorKind, character nextCharacter: CharacterProfile? = nil) {
        kind = nextKind
        if let nextCharacter {
            character = nextCharacter
        }
        animationStart = Date()
        needsDisplay = true
    }

    private func image(for profile: CharacterProfile, kind: IndicatorKind) -> NSImage? {
        let useActiveExpression = kind == .microphone || kind == .camera || kind == .live
        let cacheKey = "\(profile.id)-\(useActiveExpression ? "active" : "resting")"
        if let cached = cachedImages[cacheKey] {
            return cached
        }
        guard let loaded = loadCharacterImage(
            profile,
            useActiveExpression: useActiveExpression
        ) else { return nil }
        cachedImages[cacheKey] = loaded
        return loaded
    }

    private func startAnimation() {
        animationTimer?.invalidate()
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 30.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let image = image(for: character, kind: kind) else { return }

        let time = Date().timeIntervalSince(animationStart)
        let motion = animationValues(at: time)
        var target = aspectFit(imageSize: image.size, in: bounds.insetBy(dx: 1.5, dy: 1.5))
        let scaledWidth = target.width * character.scale
        let scaledHeight = target.height * character.scale
        target = NSRect(
            x: target.midX - scaledWidth / 2 + motion.offsetX,
            y: target.midY - scaledHeight / 2 + motion.offsetY,
            width: scaledWidth,
            height: scaledHeight
        )

        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        context.imageInterpolation = .high

        let transform = NSAffineTransform()
        transform.translateX(by: bounds.midX, yBy: bounds.midY)
        transform.rotate(byDegrees: motion.rotation)
        transform.scale(by: motion.scale)
        transform.translateX(by: -bounds.midX, yBy: -bounds.midY)
        transform.concat()

        context.cgContext.setShadow(
            offset: CGSize(width: 0, height: -1),
            blur: 5,
            color: NSColor.black.withAlphaComponent(0.12).cgColor
        )
        image.draw(
            in: target,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: true,
            hints: [.interpolation: NSImageInterpolation.high]
        )
        context.restoreGraphicsState()

        if kind == .camera || kind == .live {
            drawCameraSignal(at: time)
        }
        if kind == .microphone || kind == .live {
            drawMicrophoneSignal(at: time)
        }
        if kind == .permissionNeeded {
            drawPermissionBadge()
        }
    }

    private func animationValues(at time: TimeInterval) -> (
        offsetX: CGFloat,
        offsetY: CGFloat,
        rotation: CGFloat,
        scale: CGFloat
    ) {
        let t = CGFloat(time)
        switch kind {
        case .quiet:
            return (
                sin(t * 0.72 + 0.7) * 0.7,
                sin(t * 1.18) * 1.8,
                sin(t * 0.72) * 0.55,
                1 + sin(t * 1.18 + 0.45) * 0.007
            )
        case .microphone:
            return (
                sin(t * 0.9 + 0.8) * 0.7,
                sin(t * 1.42) * 1.7,
                sin(t * 0.95) * 0.75,
                1 + sin(t * 1.42 + 0.4) * 0.009
            )
        case .camera:
            return (
                sin(t * 0.75 + 1.1) * 0.7,
                sin(t * 1.15) * 1.7,
                sin(t * 0.7) * 0.48,
                1 + sin(t * 1.15 + 0.3) * 0.007
            )
        case .live:
            return (
                sin(t * 1.05 + 0.9) * 0.8,
                sin(t * 1.6) * 1.9,
                sin(t * 1.0) * 0.85,
                1 + sin(t * 1.6 + 0.5) * 0.010
            )
        case .permissionNeeded:
            return (0, 0, 0, 1)
        }
    }

    private func drawCameraSignal(at time: TimeInterval) {
        let pulse = 0.88 + CGFloat((sin(time * 2.8) + 1) / 2) * 0.12
        let diameter: CGFloat = 8.2 * pulse
        let dotRect = NSRect(
            x: bounds.maxX - 30 - diameter / 2,
            y: 7 - diameter / 2 + 4.1,
            width: diameter,
            height: diameter
        )

        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        context.cgContext.setShadow(
            offset: .zero,
            blur: 6,
            color: NSColor(hex: 0xf04444, alpha: 0.75).cgColor
        )
        NSColor(hex: 0xf04444).setFill()
        NSBezierPath(ovalIn: dotRect).fill()
        context.restoreGraphicsState()
    }

    private func drawMicrophoneSignal(at time: TimeInterval) {
        let center = NSPoint(x: bounds.maxX - 18, y: bounds.midY + 1)
        let alpha = 0.78 + CGFloat((sin(time * 3.0) + 1) / 2) * 0.22
        NSColor(hex: 0xff6f61, alpha: alpha).setStroke()

        for index in 0..<3 {
            let radius = CGFloat(5 + index * 5)
            let path = NSBezierPath()
            path.lineWidth = index == 0 ? 2.6 : 2.1
            path.lineCapStyle = .round
            path.appendArc(
                withCenter: center,
                radius: radius,
                startAngle: 300,
                endAngle: 60,
                clockwise: false
            )
            path.stroke()
        }
    }

    private func drawPermissionBadge() {
        let badgeRect = NSRect(x: bounds.maxX - 31, y: 5, width: 25, height: 25)
        NSColor(hex: 0xe5992b).setFill()
        NSBezierPath(ovalIn: badgeRect).fill()

        let stemWidth: CGFloat = 2.5
        let stemHeight: CGFloat = 8.2
        let gap: CGFloat = 1.6
        let dotSize: CGFloat = 3
        let totalHeight = stemHeight + gap + dotSize
        let top = badgeRect.midY - totalHeight / 2

        NSColor.white.setFill()
        let stemRect = NSRect(
            x: badgeRect.midX - stemWidth / 2,
            y: top,
            width: stemWidth,
            height: stemHeight
        )
        NSBezierPath(
            roundedRect: stemRect,
            xRadius: stemWidth / 2,
            yRadius: stemWidth / 2
        ).fill()

        let dotRect = NSRect(
            x: badgeRect.midX - dotSize / 2,
            y: top + stemHeight + gap,
            width: dotSize,
            height: dotSize
        )
        NSBezierPath(ovalIn: dotRect).fill()
    }
}

private func basicBackgroundColor(for kind: IndicatorKind) -> NSColor {
    switch kind {
    case .quiet:
        return NSColor(hex: 0x242630, alpha: 0.94)
    case .microphone:
        return NSColor(hex: 0xf04452, alpha: 0.94)
    case .camera:
        return NSColor(hex: 0x6956e8, alpha: 0.94)
    case .live:
        return NSColor(hex: 0xe51f3b, alpha: 0.94)
    case .permissionNeeded:
        return NSColor(hex: 0xd99028, alpha: 0.94)
    }
}

private func drawGlassSurface(
    in rect: NSRect,
    radius: CGFloat,
    tint: NSColor,
    glow: NSColor? = nil,
    pulse: CGFloat = 0
) {
    guard let context = NSGraphicsContext.current else { return }
    let path = NSBezierPath(roundedRect: rect, xRadius: radius, yRadius: radius)

    context.saveGraphicsState()
    context.cgContext.setShadow(
        offset: CGSize(width: 0, height: -2),
        blur: 8,
        color: NSColor.black
            .withAlphaComponent(glow == nil ? 0.14 : 0.11 + pulse * 0.015)
            .cgColor
    )
    tint.setFill()
    path.fill()
    context.cgContext.setShadow(offset: .zero, blur: 0)

    NSGradient(colorsAndLocations:
        (NSColor.white.withAlphaComponent(0.055), 0.0),
        (NSColor.white.withAlphaComponent(0.012), 0.42),
        (NSColor.white.withAlphaComponent(0.0), 1.0)
    )?.draw(in: path, angle: -90)

    let highlightRect = NSRect(
        x: rect.minX + 8,
        y: rect.minY + 4,
        width: max(0, rect.width - 16),
        height: max(4, rect.height * 0.32)
    )
    let highlight = NSBezierPath(
        roundedRect: highlightRect,
        xRadius: min(radius, highlightRect.height / 2),
        yRadius: min(radius, highlightRect.height / 2)
    )
    NSColor.white.withAlphaComponent(0.01).setFill()
    highlight.fill()

    let border = NSBezierPath(
        roundedRect: rect.insetBy(dx: 0.6, dy: 0.6),
        xRadius: max(0, radius - 0.6),
        yRadius: max(0, radius - 0.6)
    )
    border.lineWidth = 1.2
    NSColor.white.withAlphaComponent(0.28).setStroke()
    border.stroke()

    let innerBorder = NSBezierPath(
        roundedRect: rect.insetBy(dx: 2.1, dy: 2.1),
        xRadius: max(0, radius - 2.1),
        yRadius: max(0, radius - 2.1)
    )
    innerBorder.lineWidth = 0.7
    NSColor.white.withAlphaComponent(0.05).setStroke()
    innerBorder.stroke()
    context.restoreGraphicsState()
}

private func drawBasicSymbol(
    named name: String,
    in rect: NSRect,
    pointSize: CGFloat,
    color: NSColor,
    contentScale: CGFloat = 1
) {
    let symbolName = name == "exclamationmark.triangle.fill" ? "exclamationmark.triangle" : name
    guard let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) else { return }
    let configuration = NSImage.SymbolConfiguration(pointSize: pointSize, weight: .bold)
        .applying(NSImage.SymbolConfiguration(paletteColors: [color]))
    let configured = image.withSymbolConfiguration(configuration) ?? image
    let imageSize = configured.size
    guard imageSize.width > 0, imageSize.height > 0 else { return }

    let scale = min(rect.width / imageSize.width, rect.height / imageSize.height)
    var target = NSRect(
        x: rect.midX - imageSize.width * scale * contentScale / 2,
        y: rect.midY - imageSize.height * scale * contentScale / 2,
        width: imageSize.width * scale * contentScale,
        height: imageSize.height * scale * contentScale
    )
    if name == "video.fill" || name == "video.slash.fill" {
        let height = target.height * 0.78
        target = NSRect(x: target.minX, y: rect.midY - height / 2, width: target.width, height: height)
    }
    configured.draw(in: target)
}

private func drawBasicText(
    _ text: String,
    at point: NSPoint,
    size: CGFloat,
    weight: NSFont.Weight,
    color: NSColor,
    letterSpacing: CGFloat = 0
) {
    let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .kern: letterSpacing,
    ]
    NSAttributedString(string: text, attributes: attributes).draw(at: point)
}

private func drawBasicOffSymbol(named name: String, in rect: NSRect, background: NSColor) {
    let iconColor = NSColor.white.withAlphaComponent(0.55)
    drawBasicSymbol(
        named: name,
        in: rect,
        pointSize: 17,
        color: iconColor,
        contentScale: name == "video.fill" ? 0.9 : 1
    )

    let start = NSPoint(x: rect.minX + 4, y: rect.maxY - 3)
    let end = NSPoint(x: rect.maxX - 3, y: rect.minY + 4)

    let cutout = NSBezierPath()
    cutout.move(to: start)
    cutout.line(to: end)
    cutout.lineWidth = 3.3
    cutout.lineCapStyle = .round
    background.setStroke()
    cutout.stroke()

    let slash = NSBezierPath()
    slash.move(to: start)
    slash.line(to: end)
    slash.lineWidth = 1.5
    slash.lineCapStyle = .round
    iconColor.setStroke()
    slash.stroke()
}

private func drawBasicCapsule(kind: IndicatorKind, in bounds: NSRect, pulse: CGFloat) {
    let outerRect = bounds.insetBy(dx: 3, dy: 3)
    let radius = outerRect.height / 2
    let background = basicBackgroundColor(for: kind)

    if kind.isUrgent {
        let expansion = 2 + pulse * 3
        let glowRect = outerRect.insetBy(dx: -expansion, dy: -expansion)
        let glow = NSBezierPath(
            roundedRect: glowRect,
            xRadius: glowRect.height / 2,
            yRadius: glowRect.height / 2
        )
        let glowColor = kind == .camera ? NSColor(hex: 0x806cff) : NSColor(hex: 0xff314f)
        glowColor.withAlphaComponent(0.008 + pulse * 0.012).setFill()
        glow.fill()
    }

    let glassGlow: NSColor? = kind.isUrgent
        ? (kind == .camera ? NSColor(hex: 0x806cff) : NSColor(hex: 0xff314f))
        : nil
    drawGlassSurface(
        in: outerRect,
        radius: radius,
        tint: background,
        glow: glassGlow,
        pulse: pulse
    )

    func iconRect(_ x: CGFloat) -> NSRect {
        NSRect(x: x, y: outerRect.midY - 10, width: 21, height: 20)
    }

    switch kind {
    case .quiet:
        drawBasicOffSymbol(named: "mic.fill", in: iconRect(outerRect.minX + 14), background: background)
        drawBasicOffSymbol(named: "video.fill", in: iconRect(outerRect.minX + 43), background: background)
        drawBasicText(
            "모두 꺼짐",
            at: NSPoint(x: outerRect.minX + 74, y: outerRect.midY - 9),
            size: 13,
            weight: .bold,
            color: NSColor.white.withAlphaComponent(0.78)
        )
        NSColor(hex: 0x63c99b).setFill()
        NSBezierPath(
            ovalIn: NSRect(x: outerRect.maxX - 18, y: outerRect.midY - 4, width: 8, height: 8)
        ).fill()

    case .microphone, .camera, .permissionNeeded:
        let symbol: String
        let label: String
        switch kind {
        case .microphone:
            symbol = "mic.fill"
            label = "마이크 켜짐"
        case .camera:
            symbol = "video.fill"
            label = "카메라 켜짐"
        default:
            symbol = "exclamationmark.triangle.fill"
            label = "권한 필요"
        }
        drawBasicSymbol(
            named: symbol,
            in: iconRect(outerRect.minX + 14),
            pointSize: 17,
            color: .white,
            contentScale: symbol == "video.fill" ? 0.9 : 1
        )
        drawBasicText(
            label,
            at: NSPoint(x: outerRect.minX + 45, y: outerRect.midY - 9),
            size: 13,
            weight: .bold,
            color: .white
        )
        if kind != .permissionNeeded {
            drawBasicText(
                "ON",
                at: NSPoint(x: outerRect.maxX - 30, y: outerRect.midY - 7),
                size: 9,
                weight: .heavy,
                color: NSColor.white.withAlphaComponent(0.8),
                letterSpacing: 1.1
            )
        }

    case .live:
        NSColor.white.setFill()
        NSBezierPath(
            ovalIn: NSRect(x: outerRect.minX + 14, y: outerRect.midY - 4, width: 8, height: 8)
        ).fill()
        drawBasicText(
            "LIVE",
            at: NSPoint(x: outerRect.minX + 30, y: outerRect.midY - 10),
            size: 14,
            weight: .heavy,
            color: .white,
            letterSpacing: 1.2
        )
        drawBasicSymbol(
            named: "mic.fill",
            in: iconRect(outerRect.maxX - 63),
            pointSize: 14,
            color: .white,
            contentScale: 0.9
        )
        drawBasicSymbol(
            named: "video.fill",
            in: iconRect(outerRect.maxX - 35),
            pointSize: 14,
            color: .white,
            contentScale: 0.9
        )
    }
}

private func drawCenteredText(
    _ text: String, in rect: NSRect, size: CGFloat, weight: NSFont.Weight, color: NSColor
) {
    let paragraph = NSMutableParagraphStyle()
    paragraph.alignment = .center
    NSAttributedString(string: text, attributes: [
        .font: NSFont.systemFont(ofSize: size, weight: weight),
        .foregroundColor: color,
        .paragraphStyle: paragraph,
    ]).draw(in: rect)
}

private func drawDeviceSymbol(
    microphone: Bool, on: Bool, in rect: NSRect, color: NSColor, background: NSColor
) {
    let name = microphone ? "mic.fill" : "video.fill"
    if on {
        drawBasicSymbol(named: name, in: rect, pointSize: 17, color: color)
    } else {
        drawBasicOffSymbol(named: name, in: rect, background: background)
    }
}

private func drawBasicIndicator(
    kind: IndicatorKind, variant: BasicVariant = .capsule, in bounds: NSRect, pulse: CGFloat
) {
    if variant == .capsule {
        drawBasicCapsule(kind: kind, in: bounds, pulse: pulse)
        return
    }

    let dark = NSColor(hex: 0x242630, alpha: 0.94)
    let micColor = NSColor(hex: 0xf04452, alpha: 0.94)
    let cameraColor = NSColor(hex: 0x6956e8, alpha: 0.94)
    let rect = bounds.insetBy(dx: 3, dy: 3)
    let permission = kind == .permissionNeeded

    switch variant {
    case .capsule:
        break
    case .dualTiles:
        let gap: CGFloat = 6
        let tileWidth = (rect.width - gap) / 2
        for index in 0..<2 {
            let microphone = index == 0
            let on = microphone ? kind.microphoneOn : kind.cameraOn
            let background = permission ? NSColor(hex: 0xd99028) : (on ? (microphone ? micColor : cameraColor) : dark)
            let tile = NSRect(x: rect.minX + CGFloat(index) * (tileWidth + gap), y: rect.minY, width: tileWidth, height: rect.height)
            drawGlassSurface(
                in: tile,
                radius: 15,
                tint: background,
                glow: on ? background : nil,
                pulse: pulse
            )
            let icon = NSRect(x: tile.midX - 11, y: tile.minY + 7, width: 22, height: 23)
            if permission {
                drawBasicSymbol(named: "exclamationmark.triangle.fill", in: icon, pointSize: 17, color: .white)
            } else {
                drawDeviceSymbol(microphone: microphone, on: on, in: icon, color: .white, background: background)
            }
            drawCenteredText(
                permission ? "권한 필요" : "\(microphone ? "마이크" : "카메라") \(on ? "켬" : "끔")",
                in: NSRect(x: tile.minX, y: tile.minY + 36, width: tile.width, height: 16),
                size: 10, weight: .semibold, color: .white.withAlphaComponent(on || permission ? 1 : 0.7)
            )
        }
    case .iconBar:
        drawGlassSurface(
            in: rect,
            radius: rect.height / 2,
            tint: dark,
            glow: kind.isUrgent ? (kind == .camera ? cameraColor : micColor) : nil,
            pulse: pulse
        )
        for index in 0..<2 {
            let microphone = index == 0
            let on = microphone ? kind.microphoneOn : kind.cameraOn
            let centerX = rect.minX + rect.width * (index == 0 ? 0.27 : 0.73)
            let cell = NSRect(x: centerX - 17, y: rect.midY - 17, width: 34, height: 34)
            let background = permission ? NSColor(hex: 0xd99028) : (on ? (microphone ? micColor : cameraColor) : dark)
            drawGlassSurface(
                in: cell,
                radius: cell.width / 2,
                tint: background,
                glow: on ? background : nil,
                pulse: pulse
            )
            let icon = cell.insetBy(dx: 7, dy: 6)
            if permission {
                drawBasicSymbol(named: "exclamationmark.triangle.fill", in: icon, pointSize: 15, color: .white)
            } else {
                drawDeviceSymbol(microphone: microphone, on: on, in: icon, color: .white, background: background)
            }
        }
    case .statusRing:
        let circle = aspectFit(imageSize: NSSize(width: 1, height: 1), in: rect)
        let glassCircle = circle.insetBy(dx: 4, dy: 4)
        drawGlassSurface(
            in: glassCircle,
            radius: glassCircle.width / 2,
            tint: dark,
            glow: kind.isUrgent ? (kind == .camera ? cameraColor : micColor) : nil,
            pulse: pulse
        )
        let center = NSPoint(x: circle.midX, y: circle.midY)
        let radius = circle.width / 2 - 3
        for index in 0..<2 {
            let microphone = index == 0
            let on = microphone ? kind.microphoneOn : kind.cameraOn
            let color = permission ? NSColor(hex: 0xd99028) : (on ? (microphone ? micColor : cameraColor) : NSColor(hex: 0x505058))
            let arc = NSBezierPath()
            arc.appendArc(withCenter: center, radius: radius, startAngle: microphone ? 98 : 278, endAngle: microphone ? 262 : 442, clockwise: false)
            arc.lineWidth = 5 + (on ? pulse * 0.6 : 0)
            arc.lineCapStyle = .round
            color.setStroke()
            arc.stroke()
        }
        if permission {
            drawBasicSymbol(named: "exclamationmark.triangle.fill", in: circle.insetBy(dx: 26, dy: 26), pointSize: 20, color: .white)
        } else {
            for index in 0..<2 {
                let microphone = index == 0
                let on = microphone ? kind.microphoneOn : kind.cameraOn
                let icon = NSRect(x: circle.midX + (microphone ? -26 : 4), y: circle.midY - 16, width: 22, height: 22)
                drawDeviceSymbol(microphone: microphone, on: on, in: icon, color: microphone ? micColor : cameraColor, background: dark)
            }
            drawCenteredText(
                kind == .quiet ? "OFF" : "ON",
                in: NSRect(x: circle.minX, y: circle.midY + 12, width: circle.width, height: 13),
                size: 9, weight: .heavy, color: .white.withAlphaComponent(0.8)
            )
        }
    }
}

private final class BasicIndicatorView: NSView {
    private(set) var kind: IndicatorKind = .quiet
    private(set) var variant: BasicVariant = .capsule
    private var animationStart = Date()
    private var animationTimer: Timer?

    override var isFlipped: Bool { true }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.masksToBounds = false
        animationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 24.0, repeats: true) { [weak self] _ in
            self?.needsDisplay = true
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        animationTimer?.invalidate()
    }

    func apply(_ nextKind: IndicatorKind, variant nextVariant: BasicVariant? = nil) {
        if let nextVariant { variant = nextVariant }
        guard kind != nextKind || nextVariant != nil else { return }
        kind = nextKind
        animationStart = Date()
        needsDisplay = true
    }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        let time = CGFloat(Date().timeIntervalSince(animationStart))
        let pulse = (sin(time * 3.1) + 1) / 2
        let floatY: CGFloat
        switch kind {
        case .quiet:
            floatY = sin(time * 1.18) * 1.8
        case .microphone:
            floatY = sin(time * 1.42) * 1.7
        case .camera:
            floatY = sin(time * 1.15) * 1.7
        case .live:
            floatY = sin(time * 1.6) * 1.9
        case .permissionNeeded:
            floatY = 0
        }

        guard let context = NSGraphicsContext.current else { return }
        context.saveGraphicsState()
        let transform = NSAffineTransform()
        transform.translateX(by: bounds.midX, yBy: bounds.midY + floatY)
        transform.translateX(by: -bounds.midX, yBy: -bounds.midY)
        transform.concat()
        drawBasicIndicator(kind: kind, variant: variant, in: bounds, pulse: pulse)
        context.restoreGraphicsState()
    }
}

final class IndicatorPanelController: NSWindowController, NSWindowDelegate {
    private let animalView: IndicatorView
    private let basicView: BasicIndicatorView
    private var didRestorePosition = false
    private var currentKind: IndicatorKind = .quiet
    private var currentStyle: VisualStyle
    private var currentCharacter: CharacterProfile
    private var currentBasicVariant: BasicVariant

    init(style: VisualStyle, character: CharacterProfile, basicVariant: BasicVariant) {
        currentStyle = style
        currentCharacter = character
        currentBasicVariant = basicVariant
        animalView = IndicatorView(
            frame: NSRect(origin: .zero, size: VisualStyle.animal.panelSize),
            character: character
        )
        basicView = BasicIndicatorView(
            frame: NSRect(origin: .zero, size: basicVariant.panelSize)
        )

        let panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: style == .basic ? basicVariant.panelSize : style.panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = true
        panel.level = .statusBar
        panel.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .transient,
            .ignoresCycle,
        ]
        panel.isMovableByWindowBackground = true
        panel.hidesOnDeactivate = false
        panel.becomesKeyOnlyIfNeeded = true
        panel.contentView = style == .basic ? basicView : animalView

        super.init(window: panel)
        panel.delegate = self
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func show(_ kind: IndicatorKind, style: VisualStyle, character: CharacterProfile, basicVariant: BasicVariant) {
        guard let window else { return }
        currentKind = kind
        currentStyle = style
        currentCharacter = character
        currentBasicVariant = basicVariant
        applyPresentation(to: window, animated: window.isVisible)
        window.orderFrontRegardless()
        if !didRestorePosition {
            restoreOrPlaceWindow()
            didRestorePosition = true
        }
    }

    func setPresentation(style: VisualStyle, character: CharacterProfile, basicVariant: BasicVariant) {
        currentStyle = style
        currentCharacter = character
        currentBasicVariant = basicVariant
        guard let window else { return }
        applyPresentation(to: window, animated: window.isVisible)
    }

    func hidePanel() {
        window?.orderOut(nil)
    }

    private func applyPresentation(to window: NSWindow, animated: Bool) {
        let oldFrame = window.frame
        let size = currentStyle == .basic ? currentBasicVariant.panelSize : currentStyle.panelSize
        let nextFrame = NSRect(
            x: oldFrame.maxX - size.width,
            y: oldFrame.maxY - size.height,
            width: size.width,
            height: size.height
        )

        if currentStyle == .basic {
            basicView.frame = NSRect(origin: .zero, size: size)
            basicView.apply(currentKind, variant: currentBasicVariant)
            window.contentView = basicView
        } else {
            animalView.frame = NSRect(origin: .zero, size: size)
            animalView.apply(currentKind, character: currentCharacter)
            window.contentView = animalView
        }

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.2
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window.animator().setFrame(nextFrame, display: true)
            }
        } else {
            window.setFrame(nextFrame, display: true)
        }
    }

    private func restoreOrPlaceWindow() {
        guard let window else { return }
        let defaults = UserDefaults.standard
        if defaults.object(forKey: "pets.origin.x") != nil,
           defaults.object(forKey: "pets.origin.y") != nil {
            let origin = NSPoint(
                x: defaults.double(forKey: "pets.origin.x"),
                y: defaults.double(forKey: "pets.origin.y")
            )
            window.setFrameOrigin(origin)
            return
        }

        guard let screen = NSScreen.main else { return }
        let visible = screen.visibleFrame
        window.setFrameOrigin(NSPoint(
            x: visible.maxX - window.frame.width - 22,
            y: visible.maxY - window.frame.height - 90
        ))
    }

    func windowDidMove(_ notification: Notification) {
        guard let origin = window?.frame.origin else { return }
        let defaults = UserDefaults.standard
        defaults.set(origin.x, forKey: "pets.origin.x")
        defaults.set(origin.y, forKey: "pets.origin.y")
    }
}

final class ZoomStatusMonitor {
    var onObservation: ((MonitorObservation) -> Void)?

    private var timer: Timer?
    private var lastObservation: MonitorObservation?
    private var lastKnownState = DeviceState(
        microphoneOn: false,
        cameraOn: false,
        meetingActive: false
    )
    private var didRequestPermission = false

    func start() {
        stop()
        lastObservation = nil
        scan()
        timer = Timer.scheduledTimer(withTimeInterval: 0.85, repeats: true) { [weak self] _ in
            self?.scan()
        }
    }

    func stop() {
        timer?.invalidate()
        timer = nil
    }

    func openAccessibilitySettings() {
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility"
        guard let url = URL(string: urlString) else { return }
        NSWorkspace.shared.open(url)
    }

    private func scan() {
        guard let zoom = NSWorkspace.shared.runningApplications.first(where: isZoomApplication) else {
            publish(.noMeeting)
            return
        }

        guard AXIsProcessTrusted() else {
            if !didRequestPermission {
                didRequestPermission = true
                let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
                let options = [key: true] as CFDictionary
                _ = AXIsProcessTrustedWithOptions(options)
            }
            publish(.permissionNeeded)
            return
        }

        let root = AXUIElementCreateApplication(zoom.processIdentifier)
        var remainingNodes = 1_200
        var labels: [String] = []
        collectLabels(from: root, depth: 0, remainingNodes: &remainingNodes, into: &labels)

        let result = inferState(from: labels)
        guard result.meetingActive else {
            publish(.noMeeting)
            return
        }

        lastKnownState = result
        publish(.state(result))
    }

    private func isZoomApplication(_ application: NSRunningApplication) -> Bool {
        let bundleIdentifier = application.bundleIdentifier?.lowercased() ?? ""
        let name = application.localizedName?.lowercased() ?? ""
        return bundleIdentifier == "us.zoom.xos"
            || bundleIdentifier.contains("zoom")
            || name == "zoom"
            || name == "zoom workplace"
    }

    private func collectLabels(
        from element: AXUIElement,
        depth: Int,
        remainingNodes: inout Int,
        into labels: inout [String]
    ) {
        guard remainingNodes > 0, depth <= 10 else { return }
        remainingNodes -= 1

        let attributes: [CFString] = [
            kAXTitleAttribute as CFString,
            kAXDescriptionAttribute as CFString,
            kAXHelpAttribute as CFString,
            kAXValueAttribute as CFString,
        ]

        for attribute in attributes {
            var value: CFTypeRef?
            if AXUIElementCopyAttributeValue(element, attribute, &value) == .success,
               let string = value as? String,
               !string.isEmpty {
                labels.append(string)
            }
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenValue
        ) == .success,
        let children = childrenValue as? [AXUIElement] else {
            return
        }

        for child in children {
            collectLabels(
                from: child,
                depth: depth + 1,
                remainingNodes: &remainingNodes,
                into: &labels
            )
            if remainingNodes <= 0 { break }
        }
    }

    private func inferState(from rawLabels: [String]) -> DeviceState {
        let labels = rawLabels
            .map { $0.lowercased().trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { label in
                let excluded = [
                    "mute all",
                    "unmute all",
                    "ask to unmute",
                    "모두 음소거",
                    "참가자",
                ]
                return !excluded.contains(where: label.contains)
            }

        let micOffPatterns = [
            "unmute my audio",
            "unmute audio",
            "unmute microphone",
            "마이크 음소거 해제",
            "오디오 음소거 해제",
        ]
        let micOnPatterns = [
            "mute my audio",
            "mute audio",
            "mute microphone",
            "마이크 음소거",
            "오디오 음소거",
        ]
        let cameraOffPatterns = [
            "start video",
            "turn on video",
            "비디오 시작",
            "카메라 켜기",
        ]
        let cameraOnPatterns = [
            "stop video",
            "turn off video",
            "비디오 중지",
            "카메라 끄기",
        ]

        let microphone: Bool?
        if containsAny(labels, patterns: micOffPatterns) {
            microphone = false
        } else if containsAny(labels, patterns: micOnPatterns) {
            microphone = true
        } else {
            microphone = nil
        }

        let camera: Bool?
        if containsAny(labels, patterns: cameraOffPatterns) {
            camera = false
        } else if containsAny(labels, patterns: cameraOnPatterns) {
            camera = true
        } else {
            camera = nil
        }

        let meetingActive = microphone != nil || camera != nil
        return DeviceState(
            microphoneOn: microphone ?? lastKnownState.microphoneOn,
            cameraOn: camera ?? lastKnownState.cameraOn,
            meetingActive: meetingActive
        )
    }

    private func containsAny(_ labels: [String], patterns: [String]) -> Bool {
        labels.contains { label in
            patterns.contains { pattern in
                label == pattern || label.contains(pattern)
            }
        }
    }

    private func publish(_ observation: MonitorObservation) {
        guard observation != lastObservation else { return }
        lastObservation = observation
        onObservation?(observation)
    }
}

private func makeCharacterIcon(
    character: CharacterProfile,
    kind: IndicatorKind,
    phase: CGFloat = 0,
    size: NSSize = NSSize(width: 31, height: 19)
) -> NSImage {
    let result = NSImage(size: size, flipped: false) { rect in
        NSGraphicsContext.saveGraphicsState()
        let motionAmount: CGFloat = kind == .permissionNeeded ? 0 : 1
        let offsetX = sin(phase * 0.58 + 0.7) * 0.35 * motionAmount
        let offsetY = sin(phase * 0.92) * 0.8 * motionAmount
        let useActiveExpression = kind == .microphone || kind == .camera || kind == .live
        if let image = loadCharacterImage(
            character,
            useActiveExpression: useActiveExpression
        ) {
            let imageRect = aspectFit(
                imageSize: image.size,
                in: NSRect(
                    x: rect.minX + offsetX,
                    y: rect.minY + 0.5 + offsetY,
                    width: 23,
                    height: 17
                )
            )
            NSGraphicsContext.current?.imageInterpolation = .high
            image.draw(
                in: imageRect,
                from: .zero,
                operation: .sourceOver,
                fraction: 1,
                respectFlipped: false,
                hints: [.interpolation: NSImageInterpolation.high]
            )
        }

        if kind == .camera || kind == .live {
            let pulse = 0.86 + (sin(phase * 2.5) + 1) * 0.09
            let diameter = 4.8 * pulse
            let dotRect = NSRect(
                x: rect.maxX - 5.6 - diameter / 2,
                y: rect.maxY - 5.2 - diameter / 2,
                width: diameter,
                height: diameter
            )
            NSGraphicsContext.current?.cgContext.setShadow(
                offset: .zero,
                blur: 2.8,
                color: NSColor(hex: 0xf04444, alpha: 0.65).cgColor
            )
            NSColor(hex: 0xf04444).setFill()
            NSBezierPath(ovalIn: dotRect).fill()
            NSGraphicsContext.current?.cgContext.setShadow(offset: .zero, blur: 0)
        }
        if kind == .microphone || kind == .live {
            NSColor(hex: 0xff6f61).setFill()
            for index in 0..<3 {
                let wave = (sin(phase * 2.7 + CGFloat(index) * 1.45) + 1) / 2
                let height = 2.4 + wave * 4.2
                let bar = NSRect(
                    x: rect.maxX - 8.1 + CGFloat(index) * 2.35,
                    y: 1.6,
                    width: 1.45,
                    height: height
                )
                NSBezierPath(roundedRect: bar, xRadius: 0.72, yRadius: 0.72).fill()
            }
        }
        if kind == .permissionNeeded {
            NSColor(hex: 0xe5992b).setFill()
            let badgeRect = NSRect(x: rect.maxX - 9.2, y: rect.maxY - 9.2, width: 7.4, height: 7.4)
            NSBezierPath(ovalIn: badgeRect).fill()

            NSColor.white.setFill()
            NSBezierPath(
                roundedRect: NSRect(x: badgeRect.midX - 0.65, y: badgeRect.midY - 1.1, width: 1.3, height: 3.2),
                xRadius: 0.65,
                yRadius: 0.65
            ).fill()
            NSBezierPath(ovalIn: NSRect(x: badgeRect.midX - 0.7, y: badgeRect.minY + 1.1, width: 1.4, height: 1.4)).fill()
        }
        NSGraphicsContext.restoreGraphicsState()
        return true
    }
    result.isTemplate = false
    return result
}

private func makeBasicStatusIcon(
    kind: IndicatorKind,
    phase: CGFloat = 0,
    size: NSSize = NSSize(width: 18, height: 18)
) -> NSImage {
    let symbolName: String
    switch kind {
    case .quiet:
        symbolName = "checkmark.circle"
    case .microphone:
        symbolName = "mic.fill"
    case .camera:
        symbolName = "video.fill"
    case .live:
        symbolName = "record.circle.fill"
    case .permissionNeeded:
        symbolName = "exclamationmark.triangle.fill"
    }

    let configuration = NSImage.SymbolConfiguration(pointSize: 15, weight: .semibold)
    let source = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
    let result = source?.withSymbolConfiguration(configuration) ?? NSImage(size: size)
    result.size = size
    result.isTemplate = true
    return result
}

private func makeBasicPreviewImage(kind: IndicatorKind, variant: BasicVariant) -> NSImage {
    let size = variant.panelSize
    let image = NSImage(size: size, flipped: true) { rect in
        drawBasicIndicator(kind: kind, variant: variant, in: rect, pulse: 0.65)
        return true
    }
    image.isTemplate = false
    return image
}

private func makeCharacterThumbnail(
    _ character: CharacterProfile,
    kind: IndicatorKind = .live,
    size: NSSize = NSSize(width: 58, height: 43)
) -> NSImage {
    let image = NSImage(size: size, flipped: false) { rect in
        guard let source = loadCharacterImage(
            character,
            useActiveExpression: kind.isUrgent
        ) else { return true }
        let target = aspectFit(imageSize: source.size, in: rect.insetBy(dx: 2, dy: 1.5))
        source.draw(
            in: target,
            from: .zero,
            operation: .sourceOver,
            fraction: 1,
            respectFlipped: false,
            hints: [.interpolation: NSImageInterpolation.high]
        )
        return true
    }
    image.isTemplate = false
    return image
}

private final class CharacterChoiceButton: NSButton {
    let character: CharacterProfile

    var isChosen: Bool = false {
        didSet { updateAppearance() }
    }

    init(character: CharacterProfile) {
        self.character = character
        super.init(frame: .zero)
        title = character.displayName
        image = makeCharacterThumbnail(character)
        imagePosition = .imageAbove
        imageScaling = .scaleProportionallyDown
        isBordered = false
        bezelStyle = .regularSquare
        font = .systemFont(ofSize: 11, weight: .medium)
        alignment = .center
        focusRingType = .none
        wantsLayer = true
        layer?.cornerRadius = 12
        layer?.masksToBounds = true
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 84),
            heightAnchor.constraint(equalToConstant: 76),
        ])
        updateAppearance()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(kind: IndicatorKind) {
        image = makeCharacterThumbnail(character, kind: kind)
        setAccessibilityLabel("\(character.displayName), \(kind.displayName)")
    }

    private func updateAppearance() {
        layer?.backgroundColor = isChosen
            ? NSColor.controlAccentColor.withAlphaComponent(0.13).cgColor
            : NSColor.labelColor.withAlphaComponent(0.035).cgColor
        layer?.borderWidth = isChosen ? 2 : 1
        layer?.borderColor = isChosen
            ? NSColor.controlAccentColor.cgColor
            : NSColor.separatorColor.withAlphaComponent(0.42).cgColor
    }
}

private final class BasicChoiceButton: NSButton {
    let variant: BasicVariant
    var kind: IndicatorKind = .quiet { didSet { needsDisplay = true } }
    var isChosen = false { didSet { needsDisplay = true } }
    override var isFlipped: Bool { true }

    init(variant: BasicVariant) {
        self.variant = variant
        super.init(frame: .zero)
        title = ""
        isBordered = false
        setButtonType(.momentaryPushIn)
        focusRingType = .none
        wantsLayer = true
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 242),
            heightAnchor.constraint(equalToConstant: 112),
        ])
        setAccessibilityLabel("\(variant.displayName), \(variant.detail)")
        toolTip = variant.detail
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draw(_ dirtyRect: NSRect) {
        let card = NSBezierPath(roundedRect: bounds.insetBy(dx: 1, dy: 1), xRadius: 13, yRadius: 13)
        (isChosen ? NSColor.controlAccentColor.withAlphaComponent(0.075) : NSColor.controlBackgroundColor.withAlphaComponent(0.65)).setFill()
        card.fill()
        (isChosen ? NSColor.controlAccentColor : NSColor.separatorColor.withAlphaComponent(0.6)).setStroke()
        card.lineWidth = isChosen ? 1.8 : 1
        card.stroke()

        let image = makeBasicPreviewImage(kind: kind, variant: variant)
        let area = NSRect(x: 15, y: 10, width: bounds.width - 30, height: 58)
        image.draw(in: aspectFit(imageSize: image.size, in: area), from: .zero, operation: .sourceOver, fraction: 1, respectFlipped: true, hints: [.interpolation: NSImageInterpolation.high])
        drawCenteredText(variant.displayName, in: NSRect(x: 12, y: 75, width: bounds.width - 24, height: 16), size: 12, weight: .semibold, color: .labelColor)
        drawCenteredText(variant.detail, in: NSRect(x: 12, y: 94, width: bounds.width - 24, height: 14), size: 10, weight: .regular, color: .secondaryLabelColor)
        if isChosen {
            let badge = NSRect(x: bounds.width - 24, y: 9, width: 14, height: 14)
            NSColor.controlAccentColor.setFill()
            NSBezierPath(ovalIn: badge).fill()
            let check = NSBezierPath()
            check.move(to: NSPoint(x: badge.minX + 3.5, y: badge.minY + 7))
            check.line(to: NSPoint(x: badge.minX + 6, y: badge.minY + 9.5))
            check.line(to: NSPoint(x: badge.minX + 10.5, y: badge.minY + 4.5))
            check.lineWidth = 1.6
            check.lineCapStyle = .round
            check.lineJoinStyle = .round
            NSColor.white.setStroke()
            check.stroke()
        }
    }
}

private final class StatusBadgeView: NSView {
    private let dotView = NSView()
    private let textLabel = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 13
        translatesAutoresizingMaskIntoConstraints = false

        dotView.wantsLayer = true
        dotView.layer?.cornerRadius = 4
        dotView.translatesAutoresizingMaskIntoConstraints = false

        textLabel.font = .systemFont(ofSize: 11, weight: .semibold)
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(dotView)
        addSubview(textLabel)
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 26),
            dotView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            dotView.centerYAnchor.constraint(equalTo: centerYAnchor),
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),
            textLabel.leadingAnchor.constraint(equalTo: dotView.trailingAnchor, constant: 6),
            textLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            textLabel.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func update(kind: IndicatorKind, sourceMode: SourceMode, observation: MonitorObservation) {
        let presentation: (String, NSColor)
        switch kind {
        case .quiet:
            presentation = ("모두 꺼짐", NSColor(hex: 0x7e8792))
        case .microphone:
            presentation = ("마이크 켜짐", NSColor(hex: 0xff6f61))
        case .camera:
            presentation = ("카메라 켜짐", NSColor(hex: 0x6956e8))
        case .live:
            presentation = ("마이크와 카메라 켜짐", NSColor(hex: 0xf04444))
        case .permissionNeeded:
            presentation = ("접근성 권한 필요", NSColor(hex: 0xe5992b))
        }

        switch sourceMode {
        case .demo:
            textLabel.stringValue = "미리보기 · \(presentation.0)"
        case .zoom:
            textLabel.stringValue = observation == .noMeeting ? "Zoom 회의 없음" : "Zoom · \(presentation.0)"
        }
        textLabel.textColor = presentation.1
        dotView.layer?.backgroundColor = presentation.1.cgColor
        layer?.backgroundColor = presentation.1.withAlphaComponent(0.11).cgColor
    }
}

private final class CharacterPickerViewController: NSViewController {
    var onSelectCharacter: ((CharacterProfile) -> Void)?
    var onSelectStyle: ((VisualStyle) -> Void)?
    var onSelectBasicVariant: ((BasicVariant) -> Void)?
    var onSelectMode: ((SourceMode) -> Void)?
    var onOpenAccessibility: (() -> Void)?
    var onQuit: (() -> Void)?

    private var selectedCharacter: CharacterProfile
    private var selectedStyle: VisualStyle
    private var selectedBasicVariant: BasicVariant
    private var currentKind: IndicatorKind
    private var sourceMode: SourceMode
    private var observation: MonitorObservation
    private var lastDemoState = DeviceState(microphoneOn: true, cameraOn: true, meetingActive: true)
    private var choiceButtons: [CharacterChoiceButton] = []
    private var basicButtons: [BasicChoiceButton] = []
    private let statusBadge = StatusBadgeView()
    private let styleControl = NSSegmentedControl(labels: ["기본형  4종", "동물형  12종"], trackingMode: .selectOne, target: nil, action: nil)
    private let visualContainer = NSView()
    private let animalRows = NSStackView()
    private let basicRows = NSStackView()
    private let sourceControl = NSSegmentedControl(labels: ["Zoom 실제 감지", "미리보기"], trackingMode: .selectOne, target: nil, action: nil)
    private let previewControl = NSSegmentedControl(labels: ["모두 꺼짐", "마이크만 켜짐", "카메라만 켜짐", "둘 다 켜짐"], trackingMode: .selectOne, target: nil, action: nil)
    private let modeHelp = NSTextField(wrappingLabelWithString: "")

    init(character: CharacterProfile, style: VisualStyle, basicVariant: BasicVariant, kind: IndicatorKind, sourceMode: SourceMode, observation: MonitorObservation = .noMeeting) {
        selectedCharacter = character
        selectedStyle = style
        selectedBasicVariant = basicVariant
        currentKind = kind
        self.sourceMode = sourceMode
        self.observation = observation
        super.init(nibName: nil, bundle: nil)
        preferredContentSize = NSSize(width: 540, height: 548)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func loadView() {
        let root = NSView(frame: NSRect(origin: .zero, size: preferredContentSize))
        root.wantsLayer = true
        root.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view = root

        let title = NSTextField(labelWithString: "On Air Companion")
        title.font = .systemFont(ofSize: 17, weight: .bold)
        let subtitle = NSTextField(labelWithString: "화면에 떠 있는 표시기의 모양을 골라요")
        subtitle.font = .systemFont(ofSize: 11)
        subtitle.textColor = .secondaryLabelColor
        let heading = NSStackView(views: [title, subtitle])
        heading.orientation = .vertical
        heading.alignment = .leading
        heading.spacing = 3
        let header = NSStackView(views: [heading, spacer(), statusBadge])
        header.orientation = .horizontal
        header.alignment = .centerY
        header.spacing = 10

        for rows in [animalRows, basicRows] {
            rows.orientation = .vertical
            rows.alignment = .centerX
            rows.spacing = 10
            rows.translatesAutoresizingMaskIntoConstraints = false
        }
        for rowStart in stride(from: 0, to: CharacterProfile.all.count, by: 4) {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 10
            for index in rowStart..<min(rowStart + 4, CharacterProfile.all.count) {
                let button = CharacterChoiceButton(character: CharacterProfile.all[index])
                button.tag = index
                button.target = self
                button.action = #selector(selectCharacter(_:))
                choiceButtons.append(button)
                row.addArrangedSubview(button)
            }
            animalRows.addArrangedSubview(row)
        }
        for rowStart in stride(from: 0, to: BasicVariant.allCases.count, by: 2) {
            let row = NSStackView()
            row.orientation = .horizontal
            row.spacing = 12
            for index in rowStart..<min(rowStart + 2, BasicVariant.allCases.count) {
                let button = BasicChoiceButton(variant: BasicVariant.allCases[index])
                button.target = self
                button.action = #selector(selectBasicVariant(_:))
                basicButtons.append(button)
                row.addArrangedSubview(button)
            }
            basicRows.addArrangedSubview(row)
        }

        configure(styleControl, action: #selector(selectStyle(_:)))
        configure(sourceControl, action: #selector(selectSource(_:)))
        configure(previewControl, action: #selector(selectPreview(_:)))
        styleControl.setWidth(238, forSegment: 0)
        styleControl.setWidth(238, forSegment: 1)
        sourceControl.setWidth(238, forSegment: 0)
        sourceControl.setWidth(238, forSegment: 1)
        for index in 0..<previewControl.segmentCount { previewControl.setWidth(113, forSegment: index) }
        sourceControl.toolTip = "실제 Zoom 상태를 읽거나, 가상 상태로 표시 모양을 확인합니다."
        previewControl.toolTip = "미리보기 상태입니다. 실제 Zoom 장치를 제어하지 않습니다."

        visualContainer.translatesAutoresizingMaskIntoConstraints = false
        visualContainer.addSubview(animalRows)
        visualContainer.addSubview(basicRows)
        NSLayoutConstraint.activate([
            visualContainer.heightAnchor.constraint(equalToConstant: 256),
            animalRows.centerXAnchor.constraint(equalTo: visualContainer.centerXAnchor),
            animalRows.centerYAnchor.constraint(equalTo: visualContainer.centerYAnchor),
            basicRows.centerXAnchor.constraint(equalTo: visualContainer.centerXAnchor),
            basicRows.centerYAnchor.constraint(equalTo: visualContainer.centerYAnchor),
        ])

        let separator = NSBox()
        separator.boxType = .separator
        let modeTitle = NSTextField(labelWithString: "상태 확인 방식")
        modeTitle.font = .systemFont(ofSize: 11, weight: .semibold)
        modeTitle.textColor = .secondaryLabelColor
        modeHelp.font = .systemFont(ofSize: 11)
        modeHelp.textColor = .secondaryLabelColor
        modeHelp.translatesAutoresizingMaskIntoConstraints = false
        modeHelp.heightAnchor.constraint(equalToConstant: 32).isActive = true

        let settingsButton = NSButton(title: "접근성 설정", target: self, action: #selector(openAccessibility))
        settingsButton.bezelStyle = .rounded
        settingsButton.controlSize = .small
        let quitButton = NSButton(title: "종료", target: self, action: #selector(quitApplication))
        quitButton.bezelStyle = .rounded
        quitButton.controlSize = .small
        let credit = NSTextField(labelWithString: "Ara Jung · fifty UX")
        credit.font = .systemFont(ofSize: 9, weight: .medium)
        credit.textColor = .tertiaryLabelColor
        credit.toolTip = "Designed and built by Ara Jung · fifty UX"
        let footer = NSStackView(views: [settingsButton, spacer(), credit, quitButton])
        footer.orientation = .horizontal
        footer.alignment = .centerY
        footer.spacing = 8

        let content = NSStackView(views: [header, styleControl, visualContainer, separator, modeTitle, sourceControl, previewControl, modeHelp, footer])
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 10
        content.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -20),
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: 18),
            content.bottomAnchor.constraint(lessThanOrEqualTo: root.bottomAnchor, constant: -16),
        ])
        for child in [header, styleControl, visualContainer, separator, sourceControl, previewControl, modeHelp, footer] {
            child.widthAnchor.constraint(equalTo: content.widthAnchor).isActive = true
        }
        refresh(character: selectedCharacter, style: selectedStyle, basicVariant: selectedBasicVariant, kind: currentKind, sourceMode: sourceMode, observation: observation)
    }

    private func spacer() -> NSView {
        let view = NSView()
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return view
    }

    private func configure(_ control: NSSegmentedControl, action: Selector) {
        control.segmentStyle = .rounded
        control.target = self
        control.action = action
        control.translatesAutoresizingMaskIntoConstraints = false
    }

    func refresh(character: CharacterProfile, style: VisualStyle, basicVariant: BasicVariant, kind: IndicatorKind, sourceMode: SourceMode, observation: MonitorObservation) {
        selectedCharacter = character
        selectedStyle = style
        selectedBasicVariant = basicVariant
        currentKind = kind
        self.sourceMode = sourceMode
        self.observation = observation
        guard isViewLoaded else { return }

        for button in choiceButtons {
            button.isChosen = button.character.id == character.id
            button.update(kind: kind)
        }
        for button in basicButtons {
            button.isChosen = button.variant == basicVariant
            button.kind = kind
            button.setAccessibilityValue(button.isChosen ? "선택됨" : "선택 안 됨")
        }
        styleControl.selectedSegment = style == .basic ? 0 : 1
        basicRows.isHidden = style != .basic
        animalRows.isHidden = style != .animal
        statusBadge.update(kind: kind, sourceMode: sourceMode, observation: observation)

        switch sourceMode {
        case .zoom:
            sourceControl.selectedSegment = 0
            previewControl.isEnabled = false
            previewControl.selectedSegment = -1
            switch observation {
            case .noMeeting:
                modeHelp.stringValue = "Zoom 회의가 감지되면 표시기가 나타나요.\n미리보기에서 네 가지 상태를 먼저 확인할 수 있어요."
            case .permissionNeeded:
                modeHelp.stringValue = "Zoom 상태를 읽으려면 접근성 권한이 필요해요.\n아래의 접근성 설정에서 권한을 켜 주세요."
            case .state:
                modeHelp.stringValue = "실제 Zoom 회의 상태를 표시하고 있어요.\n이 앱은 마이크와 카메라를 직접 켜거나 끄지 않아요."
            }
        case .demo(let state):
            lastDemoState = state
            sourceControl.selectedSegment = 1
            previewControl.isEnabled = true
            previewControl.selectedSegment = state.microphoneOn ? (state.cameraOn ? 3 : 1) : (state.cameraOn ? 2 : 0)
            modeHelp.stringValue = "가상 상태로 표시 모양을 확인하고 있어요. 실제 Zoom 상태와 무관해요.\n상태 버튼은 Zoom의 마이크나 카메라를 켜지 않아요."
        }
    }

    @objc private func selectCharacter(_ sender: CharacterChoiceButton) { onSelectCharacter?(sender.character) }
    @objc private func selectBasicVariant(_ sender: BasicChoiceButton) { onSelectBasicVariant?(sender.variant) }
    @objc private func selectStyle(_ sender: NSSegmentedControl) { onSelectStyle?(sender.selectedSegment == 0 ? .basic : .animal) }

    @objc private func selectSource(_ sender: NSSegmentedControl) {
        onSelectMode?(sender.selectedSegment == 0 ? .zoom : .demo(lastDemoState))
    }

    @objc private func selectPreview(_ sender: NSSegmentedControl) {
        let state = DeviceState(microphoneOn: sender.selectedSegment == 1 || sender.selectedSegment == 3, cameraOn: sender.selectedSegment == 2 || sender.selectedSegment == 3, meetingActive: true)
        onSelectMode?(.demo(state))
    }

    @objc private func openAccessibility() { onOpenAccessibility?() }
    @objc private func quitApplication() { onQuit?() }
}


final class AppDelegate: NSObject, NSApplicationDelegate {
    private let monitor = ZoomStatusMonitor()
    private var selectedCharacter: CharacterProfile
    private var visualStyle: VisualStyle
    private var basicVariant: BasicVariant
    private lazy var panelController = IndicatorPanelController(
        style: visualStyle,
        character: selectedCharacter,
        basicVariant: basicVariant
    )
    private var statusItem: NSStatusItem?
    private var sourceMode: SourceMode = .zoom
    private var currentKind: IndicatorKind = .quiet
    private var currentObservation: MonitorObservation = .noMeeting
    private var statusAnimationTimer: Timer?
    private let statusAnimationStart = Date()
    private let pickerPopover = NSPopover()
    private var pickerController: CharacterPickerViewController?

    override init() {
        let storedID = UserDefaults.standard.string(forKey: "pets.character.id")
        selectedCharacter = CharacterProfile.character(withID: storedID) ?? .defaultCharacter
        let storedStyle = UserDefaults.standard.string(forKey: "companion.visual.style")
        visualStyle = VisualStyle(rawValue: storedStyle ?? "") ?? .animal
        basicVariant = BasicVariant(rawValue: UserDefaults.standard.string(forKey: "companion.basic.variant") ?? "") ?? .capsule
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        configureStatusItem()
        configureMonitor()
        applyLaunchArguments()
    }

    private func configureStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            button.imagePosition = .imageOnly
            button.toolTip = "On Air Companion"
            button.target = self
            button.action = #selector(togglePicker)
            button.sendAction(on: [.leftMouseUp])
        }
        statusItem = item
        configurePicker()
        startStatusAnimation()
        updateStatusIcon()
    }

    deinit {
        statusAnimationTimer?.invalidate()
    }

    private func configurePicker() {
        let controller = CharacterPickerViewController(
            character: selectedCharacter,
            style: visualStyle,
            basicVariant: basicVariant,
            kind: currentKind,
            sourceMode: sourceMode,
            observation: currentObservation
        )
        controller.onSelectCharacter = { [weak self] character in
            self?.selectCharacter(character)
        }
        controller.onSelectStyle = { [weak self] style in
            self?.selectVisualStyle(style)
        }
        controller.onSelectBasicVariant = { [weak self] variant in
            self?.selectBasicVariant(variant)
        }
        controller.onSelectMode = { [weak self] mode in
            self?.setMode(mode)
        }
        controller.onOpenAccessibility = { [weak self] in
            self?.monitor.openAccessibilitySettings()
        }
        controller.onQuit = {
            NSApp.terminate(nil)
        }

        pickerPopover.behavior = .transient
        pickerPopover.animates = true
        pickerPopover.contentSize = controller.preferredContentSize
        pickerPopover.contentViewController = controller
        pickerController = controller
    }

    private func startStatusAnimation() {
        statusAnimationTimer?.invalidate()
        statusAnimationTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 12.0, repeats: true) { [weak self] _ in
            self?.updateStatusIcon()
        }
    }

    private func configureMonitor() {
        monitor.onObservation = { [weak self] observation in
            DispatchQueue.main.async {
                guard let self, self.sourceMode == .zoom else { return }
                self.currentObservation = observation
                switch observation {
                case .noMeeting:
                    self.currentKind = .quiet
                    self.panelController.hidePanel()
                case .permissionNeeded:
                    self.currentKind = .permissionNeeded
                    self.panelController.show(
                        .permissionNeeded,
                        style: self.visualStyle,
                        character: self.selectedCharacter,
                        basicVariant: self.basicVariant
                    )
                case .state(let state):
                    self.currentKind = IndicatorKind(state: state)
                    self.panelController.show(
                        self.currentKind,
                        style: self.visualStyle,
                        character: self.selectedCharacter,
                        basicVariant: self.basicVariant
                    )
                }
                self.refreshPicker()
                self.updateStatusIcon()
            }
        }
    }

    private func applyLaunchArguments() {
        let arguments = CommandLine.arguments
        if let characterIndex = arguments.firstIndex(of: "--character"),
           arguments.indices.contains(characterIndex + 1),
           let character = CharacterProfile.character(withID: arguments[characterIndex + 1]) {
            selectedCharacter = character
            UserDefaults.standard.set(character.id, forKey: "pets.character.id")
        }

        if let styleIndex = arguments.firstIndex(of: "--style"),
           arguments.indices.contains(styleIndex + 1),
           let style = VisualStyle(rawValue: arguments[styleIndex + 1]) {
            visualStyle = style
            UserDefaults.standard.set(style.rawValue, forKey: "companion.visual.style")
        }

        let argumentSet = Set(arguments)
        if let index = arguments.firstIndex(of: "--basic-variant"),
           arguments.indices.contains(index + 1),
           let variant = BasicVariant(rawValue: arguments[index + 1]) {
            basicVariant = variant
            UserDefaults.standard.set(variant.rawValue, forKey: "companion.basic.variant")
        }
        if argumentSet.contains("--demo-mic") {
            setMode(.demo(DeviceState(microphoneOn: true, cameraOn: false, meetingActive: true)))
        } else if argumentSet.contains("--demo-camera") {
            setMode(.demo(DeviceState(microphoneOn: false, cameraOn: true, meetingActive: true)))
        } else if argumentSet.contains("--demo-live") {
            setMode(.demo(DeviceState(microphoneOn: true, cameraOn: true, meetingActive: true)))
        } else if argumentSet.contains("--demo-quiet") {
            setMode(.demo(.quiet))
        } else {
            setMode(.zoom)
        }
        updateStatusIcon()

        if argumentSet.contains("--show-picker") {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
                self?.showPicker()
            }
        }
    }

    private func setMode(_ mode: SourceMode) {
        sourceMode = mode
        switch mode {
        case .zoom:
            currentKind = .quiet
            currentObservation = .noMeeting
            panelController.hidePanel()
            monitor.start()
        case .demo(let state):
            monitor.stop()
            currentKind = IndicatorKind(state: state)
            panelController.show(
                currentKind,
                style: visualStyle,
                character: selectedCharacter,
                basicVariant: basicVariant
            )
        }
        refreshPicker()
        updateStatusIcon()
    }

    private func updateStatusIcon() {
        guard let button = statusItem?.button else { return }
        let phase = CGFloat(Date().timeIntervalSince(statusAnimationStart))
        if visualStyle == .basic {
            button.image = makeBasicStatusIcon(kind: currentKind, phase: phase)
            button.image?.accessibilityDescription = "기본형, \(currentKind.filename)"
        } else {
            button.image = makeCharacterIcon(
                character: selectedCharacter,
                kind: currentKind,
                phase: phase
            )
            button.image?.accessibilityDescription = "\(selectedCharacter.displayName), \(currentKind.filename)"
        }
        let statusDescription: String
        switch sourceMode {
        case .demo: statusDescription = "미리보기 · \(currentKind.displayName)"
        case .zoom: statusDescription = currentObservation == .noMeeting ? "Zoom 회의 없음" : "Zoom · \(currentKind.displayName)"
        }
        button.toolTip = "On Air Companion · \(visualStyle == .basic ? basicVariant.displayName : selectedCharacter.displayName) · \(statusDescription)"
    }

    private func refreshPicker() {
        pickerController?.refresh(
            character: selectedCharacter,
            style: visualStyle,
            basicVariant: basicVariant,
            kind: currentKind,
            sourceMode: sourceMode,
            observation: currentObservation
        )
    }

    private func selectCharacter(_ character: CharacterProfile) {
        selectedCharacter = character
        visualStyle = .animal
        UserDefaults.standard.set(character.id, forKey: "pets.character.id")
        UserDefaults.standard.set(visualStyle.rawValue, forKey: "companion.visual.style")
        panelController.setPresentation(style: visualStyle, character: character, basicVariant: basicVariant)
        refreshPicker()
        updateStatusIcon()
    }

    private func selectVisualStyle(_ style: VisualStyle) {
        visualStyle = style
        UserDefaults.standard.set(style.rawValue, forKey: "companion.visual.style")
        panelController.setPresentation(style: style, character: selectedCharacter, basicVariant: basicVariant)
        refreshPicker()
        updateStatusIcon()
    }

    @objc private func togglePicker() {
        if pickerPopover.isShown {
            pickerPopover.performClose(nil)
        } else {
            showPicker()
        }
    }

    private func selectBasicVariant(_ variant: BasicVariant) {
        basicVariant = variant
        visualStyle = .basic
        UserDefaults.standard.set(variant.rawValue, forKey: "companion.basic.variant")
        UserDefaults.standard.set(visualStyle.rawValue, forKey: "companion.visual.style")
        panelController.setPresentation(style: .basic, character: selectedCharacter, basicVariant: variant)
        refreshPicker()
        updateStatusIcon()
    }

    private func showPicker() {
        guard let button = statusItem?.button else { return }
        refreshPicker()
        NSApp.activate(ignoringOtherApps: true)
        pickerPopover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }
}

private func renderView(_ view: NSView, to url: URL) throws {
    view.layoutSubtreeIfNeeded()
    guard let representation = view.bitmapImageRepForCachingDisplay(in: view.bounds) else { return }
    view.cacheDisplay(in: view.bounds, to: representation)
    guard let data = representation.representation(using: .png, properties: [:]) else { return }
    try data.write(to: url)
}

private func exportPreviews(to destination: String) throws {
    let fileManager = FileManager.default
    let root = URL(fileURLWithPath: destination, isDirectory: true)
    let statesRoot = root.appendingPathComponent("states", isDirectory: true)
    let menuIconsRoot = root.appendingPathComponent("menu-icons", isDirectory: true)
    let basicStatesRoot = root.appendingPathComponent("basic-states", isDirectory: true)
    let basicIconsRoot = root.appendingPathComponent("basic-menu-icons", isDirectory: true)
    let activeCharactersRoot = root.appendingPathComponent("characters-active", isDirectory: true)
    try fileManager.createDirectory(at: statesRoot, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: menuIconsRoot, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: basicStatesRoot, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: basicIconsRoot, withIntermediateDirectories: true)
    try fileManager.createDirectory(at: activeCharactersRoot, withIntermediateDirectories: true)

    let variantsRoot = root.appendingPathComponent("basic-variants", isDirectory: true)
    try fileManager.createDirectory(at: variantsRoot, withIntermediateDirectories: true)
    for variant in BasicVariant.allCases {
        let directory = variantsRoot.appendingPathComponent(variant.rawValue, isDirectory: true)
        try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        for kind in IndicatorKind.allCases {
            let view = BasicIndicatorView(frame: NSRect(origin: .zero, size: variant.panelSize))
            view.apply(kind, variant: variant)
            try renderView(view, to: directory.appendingPathComponent("\(kind.filename).png"))
        }
    }

    for kind in [IndicatorKind.quiet, .microphone, .camera, .live] {
        let state = DeviceState(microphoneOn: kind.microphoneOn, cameraOn: kind.cameraOn, meetingActive: true)
        let picker = CharacterPickerViewController(character: .defaultCharacter, style: .basic, basicVariant: .capsule, kind: kind, sourceMode: .demo(state))
        try renderView(picker.view, to: root.appendingPathComponent("picker-basic-\(kind.filename).png"))
    }
    for observation in [MonitorObservation.noMeeting, .permissionNeeded] {
        let kind: IndicatorKind = observation == .noMeeting ? .quiet : .permissionNeeded
        let picker = CharacterPickerViewController(character: .defaultCharacter, style: .basic, basicVariant: .dualTiles, kind: kind, sourceMode: .zoom, observation: observation)
        try renderView(picker.view, to: root.appendingPathComponent("picker-zoom-\(observation == .noMeeting ? "no-meeting" : "permission").png"))
    }
    for kind in [IndicatorKind.quiet, .microphone, .camera, .live] {
        let state = DeviceState(
            microphoneOn: kind.microphoneOn,
            cameraOn: kind.cameraOn,
            meetingActive: true
        )
        let animalPicker = CharacterPickerViewController(
            character: .defaultCharacter,
            style: .animal,
            basicVariant: .capsule,
            kind: kind,
            sourceMode: .demo(state)
        )
        try renderView(
            animalPicker.view,
            to: root.appendingPathComponent("picker-animal-\(kind.filename).png")
        )
    }

    for kind in IndicatorKind.allCases {
        let view = BasicIndicatorView(
            frame: NSRect(origin: .zero, size: VisualStyle.basic.panelSize)
        )
        view.apply(kind)
        try renderView(
            view,
            to: basicStatesRoot.appendingPathComponent("\(kind.filename).png")
        )

        let icon = makeBasicStatusIcon(kind: kind, phase: 0.65)
        if let iconData = icon.tiffRepresentation,
           let bitmap = NSBitmapImageRep(data: iconData),
           let png = bitmap.representation(using: .png, properties: [:]) {
            try png.write(to: basicIconsRoot.appendingPathComponent("\(kind.filename).png"))
        }
    }

    for character in CharacterProfile.all {
        if let activeSource = Bundle.main.url(
            forResource: character.assetName,
            withExtension: "png",
            subdirectory: "CharactersActive"
        ) {
            let activeDestination = activeCharactersRoot
                .appendingPathComponent("\(character.assetName).png")
            try? fileManager.removeItem(at: activeDestination)
            try fileManager.copyItem(at: activeSource, to: activeDestination)
        }

        let characterDirectory = statesRoot.appendingPathComponent(character.id, isDirectory: true)
        let iconDirectory = menuIconsRoot.appendingPathComponent(character.id, isDirectory: true)
        try fileManager.createDirectory(at: characterDirectory, withIntermediateDirectories: true)
        try fileManager.createDirectory(at: iconDirectory, withIntermediateDirectories: true)

        for kind in IndicatorKind.allCases {
            let view = IndicatorView(
                frame: NSRect(origin: .zero, size: VisualStyle.animal.panelSize),
                character: character
            )
            view.apply(kind, character: character)
            try renderView(
                view,
                to: characterDirectory.appendingPathComponent("\(kind.filename).png")
            )

            let icon = makeCharacterIcon(
                character: character,
                kind: kind,
                size: NSSize(width: 44, height: 36)
            )
            guard let iconData = icon.tiffRepresentation,
                  let bitmap = NSBitmapImageRep(data: iconData),
                  let png = bitmap.representation(using: .png, properties: [:]) else { continue }
            try png.write(to: iconDirectory.appendingPathComponent("\(kind.filename).png"))
        }
    }
}

let application = NSApplication.shared

if let exportFlagIndex = CommandLine.arguments.firstIndex(of: "--export-previews"),
   CommandLine.arguments.indices.contains(exportFlagIndex + 1) {
    try exportPreviews(to: CommandLine.arguments[exportFlagIndex + 1])
    exit(EXIT_SUCCESS)
}

let delegate = AppDelegate()
application.delegate = delegate
application.run()
