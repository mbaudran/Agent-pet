import CoreGraphics
import Testing
@testable import KeloqzCore

private let laptop = CGRect(x: 0, y: 0, width: 1440, height: 900)
private let monitor = CGRect(x: 1440, y: 0, width: 2560, height: 1440)
private let size = CGSize(width: 300, height: 200)

@Test func insideOriginUnchanged() {
    let origin = CGPoint(x: 500, y: 300)
    #expect(clampedOrigin(origin, size: size, screens: [laptop]) == origin)
}

@Test func clampMovesOffscreenPanelOntoNearestScreen() {
    #expect(clampedOrigin(CGPoint(x: 3000, y: 100), size: size, screens: [laptop]) == CGPoint(x: 1140, y: 100))
}

@Test func picksNearestOfTwoScreens() {
    let clamped = clampedOrigin(CGPoint(x: 2500, y: -600), size: size, screens: [laptop, monitor])
    #expect(clamped == CGPoint(x: 2500, y: 0))
}

@Test func straddlingTwoScreensIsPulledOntoOne() {
    let clamped = clampedOrigin(CGPoint(x: 1300, y: 100), size: size, screens: [laptop, monitor])
    #expect(clamped == CGPoint(x: 1440, y: 100))
}

@Test func noScreensLeavesOriginAlone() {
    #expect(clampedOrigin(CGPoint(x: 9, y: 9), size: size, screens: []) == CGPoint(x: 9, y: 9))
}
