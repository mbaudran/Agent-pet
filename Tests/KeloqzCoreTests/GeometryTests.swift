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

// The panel is mostly transparent room for the bubble and toolbar; only the
// dog has to stay on screen, so it can sit right in a corner.
private let screen = CGRect(x: 0, y: 0, width: 1710, height: 1073)
private let panelSize = CGSize(width: 300, height: 240)
private let dog = CGRect(x: 86, y: 40, width: 128, height: 96)

@Test func dogCanSitInTheBottomRightCorner() {
    let corner = CGPoint(x: 1710 - 86 - 128, y: -40) // dog flush with the right and bottom edges
    #expect(clampedOrigin(corner, size: panelSize, keep: dog, screens: [screen]) == corner)
}

@Test func onlyTheDogIsPulledBackOnScreen() {
    #expect(clampedOrigin(CGPoint(x: 1600, y: -80), size: panelSize, keep: dog, screens: [screen]) == CGPoint(x: 1496, y: -40))
}

// The bubble (at most 292 pt wide) is centred over the dog and slides just
// far enough to stay on screen; the panel is wide enough (600) to draw it there.
@Test func inTheCornerTheToolbarGoesAboveAndTheBubbleShiftsLeft() {
    let panel = CGRect(x: 1710 - 236 - 128, y: -40, width: 600, height: 240) // dog flush bottom-right
    let layout = edgeLayout(panel: panel, toolbarHeight: 36, bubbleWidth: 292, screen: screen)
    #expect(layout == EdgeLayout(toolbarAbove: true, bubbleShift: -82))
    // the shifted bubble stays inside the panel, so nothing gets clipped
    #expect(panel.width / 2 - 146 + layout.bubbleShift >= 0)
}

@Test func awayFromEdgesNothingMoves() {
    let layout = edgeLayout(panel: CGRect(x: 500, y: 300, width: 600, height: 240), toolbarHeight: 36, bubbleWidth: 292, screen: screen)
    #expect(layout == EdgeLayout(toolbarAbove: false, bubbleShift: 0))
}

@Test func atTheLeftEdgeTheBubbleShiftsRight() {
    let layout = edgeLayout(panel: CGRect(x: -236, y: 300, width: 600, height: 240), toolbarHeight: 36, bubbleWidth: 292, screen: screen)
    #expect(layout.bubbleShift == 82)
}

@Test func panelOverhangingTheEdgeDoesNotShiftABubbleThatFits() {
    // the panel hangs off the right edge, but the bubble centred on the dog is still on screen
    let layout = edgeLayout(panel: CGRect(x: 1200, y: 300, width: 600, height: 240), toolbarHeight: 36, bubbleWidth: 292, screen: screen)
    #expect(layout.bubbleShift == 0)
}
