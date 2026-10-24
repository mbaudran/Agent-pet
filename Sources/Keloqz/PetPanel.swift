import AppKit
import Combine
import KeloqzCore
import SwiftUI

/// The floating, draggable, always-on-top panel Keloqz lives in. It never
/// takes focus, shows on every Space and over full-screen apps, and keeps its
/// position across launches and screen changes.
@MainActor
final class PetPanel: NSPanel {
    static let width: CGFloat = 300
    static let bubbleHeight: CGFloat = 64
    static let toolbarHeight: CGFloat = 36
    static let spacing: CGFloat = 4

    static func height(scale: Int) -> CGFloat {
        bubbleHeight + CGFloat(48 * scale) + toolbarHeight + spacing * 2
    }

    private let prefs: Preferences
    private var observers: [AnyCancellable] = []

    init(prefs: Preferences, player: SpritePlayer) {
        self.prefs = prefs
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: Self.width, height: Self.height(scale: prefs.scale)),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = false
        hidesOnDeactivate = false
        isMovableByWindowBackground = false

        let drag = DragMover(panel: self)
        contentView = FirstMouseHostingView(rootView: PetView(prefs: prefs, player: player, drag: drag))

        prefs.$scale.dropFirst().sink { [weak self] scale in self?.resize(scale: scale) }.store(in: &observers)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in self?.keepOnScreen() }
            .store(in: &observers)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show() {
        setFrameOrigin(prefs.panelOrigin ?? defaultOrigin())
        keepOnScreen()
        orderFrontRegardless()
    }

    func dragEnded() {
        keepOnScreen()
        prefs.panelOrigin = frame.origin
    }

    private func resize(scale: Int) {
        setContentSize(NSSize(width: Self.width, height: Self.height(scale: scale)))
        keepOnScreen()
    }

    private func keepOnScreen() {
        let origin = clampedOrigin(frame.origin, size: frame.size, screens: NSScreen.screens.map(\.visibleFrame))
        if origin != frame.origin { setFrameOrigin(origin) }
    }

    private func defaultOrigin() -> CGPoint {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        return CGPoint(x: screen.maxX - Self.width - 16, y: screen.minY + 8)
    }
}

/// Lets the first click land on SwiftUI controls even though the panel never
/// becomes key.
final class FirstMouseHostingView<Content: View>: NSHostingView<Content> {
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool { true }
}

/// Moves the panel with the mouse; a press that moves less than 3 pt is a click.
@MainActor
final class DragMover {
    static let clickSlop: CGFloat = 3

    private weak var panel: PetPanel?
    private var startMouse: CGPoint?
    private var startOrigin: CGPoint = .zero
    private var moved = false

    init(panel: PetPanel) {
        self.panel = panel
    }

    func changed() {
        guard let panel else { return }
        let mouse = NSEvent.mouseLocation
        guard let start = startMouse else {
            startMouse = mouse
            startOrigin = panel.frame.origin
            moved = false
            return
        }
        let dx = mouse.x - start.x, dy = mouse.y - start.y
        if abs(dx) > Self.clickSlop || abs(dy) > Self.clickSlop { moved = true }
        if moved { panel.setFrameOrigin(CGPoint(x: startOrigin.x + dx, y: startOrigin.y + dy)) }
    }

    /// Returns true when the press was a click rather than a drag.
    func ended() -> Bool {
        defer { startMouse = nil }
        if moved { panel?.dragEnded() }
        return !moved
    }
}
