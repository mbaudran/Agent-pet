import CoreGraphics

/// Keeps the panel on a visible screen: unchanged when it already fits fully
/// inside one of `screens` (visible frames), otherwise the closest origin that
/// fits inside the screen nearest to the panel's centre.
public func clampedOrigin(_ origin: CGPoint, size: CGSize, screens: [CGRect]) -> CGPoint {
    let frame = CGRect(origin: origin, size: size)
    if screens.isEmpty || screens.contains(where: { $0.contains(frame) }) { return origin }
    let centre = CGPoint(x: frame.midX, y: frame.midY)
    let distance = { (s: CGRect) -> CGFloat in
        let dx = max(s.minX - centre.x, 0, centre.x - s.maxX)
        let dy = max(s.minY - centre.y, 0, centre.y - s.maxY)
        return dx * dx + dy * dy
    }
    let screen = screens.min { distance($0) < distance($1) }!
    return CGPoint(
        x: min(max(origin.x, screen.minX), screen.maxX - size.width),
        y: min(max(origin.y, screen.minY), screen.maxY - size.height)
    )
}
