import CoreGraphics

/// Keeps the panel on a visible screen: unchanged when it already fits fully
/// inside one of `screens` (visible frames), otherwise the closest origin that
/// fits inside the screen nearest to the panel's centre.
public func clampedOrigin(_ origin: CGPoint, size: CGSize, screens: [CGRect]) -> CGPoint {
    clampedOrigin(origin, size: size, keep: CGRect(origin: .zero, size: size), screens: screens)
}

/// Same, but only the `keep` part of the panel (in panel coordinates, e.g. the
/// dog) has to stay on screen; the transparent rest may hang off the edge.
public func clampedOrigin(_ origin: CGPoint, size: CGSize, keep: CGRect, screens: [CGRect]) -> CGPoint {
    let kept = keep.offsetBy(dx: origin.x, dy: origin.y)
    if screens.isEmpty || screens.contains(where: { $0.contains(kept) }) { return origin }
    let centre = CGPoint(x: kept.midX, y: kept.midY)
    let distance = { (s: CGRect) -> CGFloat in
        let dx = max(s.minX - centre.x, 0, centre.x - s.maxX)
        let dy = max(s.minY - centre.y, 0, centre.y - s.maxY)
        return dx * dx + dy * dy
    }
    let screen = screens.min { distance($0) < distance($1) }!
    let x = min(max(kept.minX, screen.minX), screen.maxX - kept.width)
    let y = min(max(kept.minY, screen.minY), screen.maxY - kept.height)
    return CGPoint(x: x - keep.minX, y: y - keep.minY)
}

/// How the bubble and toolbar make room when the dog sits at a screen edge.
public struct EdgeLayout: Equatable, Sendable {
    /// The toolbar slot under the dog is off screen: show the toolbar above it.
    public let toolbarAbove: Bool
    /// Horizontal nudge that keeps the bubble on screen.
    public let bubbleShift: CGFloat

    public init(toolbarAbove: Bool, bubbleShift: CGFloat) {
        self.toolbarAbove = toolbarAbove
        self.bubbleShift = bubbleShift
    }
}

/// `bubbleWidth` is the widest the bubble gets; it is centred on the panel
/// (over the dog) and slides only as far as it must to stay on screen.
public func edgeLayout(panel: CGRect, toolbarHeight: CGFloat, bubbleWidth: CGFloat, screen: CGRect) -> EdgeLayout {
    let half = bubbleWidth / 2
    var shift: CGFloat = 0
    if panel.midX + half > screen.maxX { shift = screen.maxX - (panel.midX + half) }
    if panel.midX - half < screen.minX { shift = screen.minX - (panel.midX - half) }
    return EdgeLayout(toolbarAbove: panel.minY < screen.minY, bubbleShift: shift)
}
