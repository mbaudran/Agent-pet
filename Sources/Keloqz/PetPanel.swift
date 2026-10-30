import AppKit
import Combine
import KeloqzCore
import SwiftUI

/// The floating, draggable, always-on-top panel Keloqz lives in. It never
/// takes focus, shows on every Space and over full-screen apps, and keeps its
/// position across launches and screen changes.
@MainActor
final class PetPanel: NSPanel {
    /// Wide enough that the bubble can slide fully onto the screen when the dog sits in a corner.
    static let width: CGFloat = 600
    static let bubbleMaxWidth: CGFloat = 292
    static let bubbleHeight: CGFloat = 64
    static let toolbarHeight: CGFloat = 36
    static let spacing: CGFloat = 4
    /// Room above the dog: the bubble, plus the toolbar when it can't go below.
    static let bubbleArea: CGFloat = bubbleHeight + toolbarHeight

    static func height(scale: Int) -> CGFloat {
        bubbleArea + CGFloat(48 * scale) + toolbarHeight + spacing * 2
    }

    /// Where the dog sits inside the panel (bottom-left origin). Only this
    /// part has to stay on screen.
    static func dogRect(scale: Int) -> CGRect {
        let s = CGFloat(scale)
        return CGRect(x: (width - 64 * s) / 2, y: toolbarHeight + spacing, width: 64 * s, height: 48 * s)
    }

    let layout = PanelLayout()
    private let prefs: Preferences
    private let list: SessionListPanel
    private let menuBar: MenuBarItem
    private var observers: [AnyCancellable] = []

    init(model: AppModel) {
        let prefs = model.prefs
        self.prefs = prefs
        list = SessionListPanel(model: model)
        menuBar = MenuBarItem(model: model)
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
        let hosting = FirstMouseHostingView(rootView: PetView(model: model, prefs: prefs, player: model.player,
                                                             layout: layout, drag: drag))
        hosting.sizingOptions = [] // the panel keeps its size; showing the bubble or toolbar must not move the dog
        contentView = hosting

        model.$isListOpen.dropFirst().removeDuplicates().sink { [weak self] open in
            guard let self else { return }
            if open { self.list.show(beside: self) } else { self.list.hide() }
        }.store(in: &observers)
        prefs.$minimized.dropFirst().removeDuplicates().sink { [weak self] minimized in
            guard let self else { return }
            if minimized { self.orderOut(nil) } else { self.orderFrontRegardless() }
            self.menuBar.setVisible(minimized)
        }.store(in: &observers)
        prefs.$scale.dropFirst().sink { [weak self] scale in self?.resize(scale: scale) }.store(in: &observers)
        NotificationCenter.default.publisher(for: NSApplication.didChangeScreenParametersNotification)
            .sink { [weak self] _ in self?.keepOnScreen() }
            .store(in: &observers)
        NotificationCenter.default.publisher(for: NSWindow.didMoveNotification, object: self)
            .sink { [weak self] _ in self?.updateEdgeLayout() }
            .store(in: &observers)
    }

    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }

    func show() {
        setFrameOrigin(prefs.panelOrigin ?? defaultOrigin())
        keepOnScreen()
        updateEdgeLayout()
        if prefs.minimized { menuBar.setVisible(true) } else { orderFrontRegardless() }
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
        let origin = clampedOrigin(frame.origin, size: frame.size, keep: Self.dogRect(scale: prefs.scale),
                                   screens: NSScreen.screens.map(\.visibleFrame))
        if origin != frame.origin { setFrameOrigin(origin) }
        updateEdgeLayout()
    }

    private func updateEdgeLayout() {
        guard let screen = (screen ?? NSScreen.main)?.visibleFrame else { return }
        let edge = edgeLayout(panel: frame, toolbarHeight: Self.toolbarHeight, bubbleWidth: Self.bubbleMaxWidth, screen: screen)
        if edge != layout.edge { layout.edge = edge }
    }

    /// First launch: the dog in the bottom-right corner, where MasIAPet sat.
    private func defaultOrigin() -> CGPoint {
        let screen = (NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        let dog = Self.dogRect(scale: prefs.scale)
        return CGPoint(x: screen.maxX - 10 - dog.maxX, y: screen.minY + 4 - dog.minY)
    }
}

/// The edge adjustments the view draws with.
@MainActor
final class PanelLayout: ObservableObject {
    @Published var edge = EdgeLayout(toolbarAbove: false, bubbleShift: 0)
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
    private var lastX: CGFloat = 0
    private var moved = false

    init(panel: PetPanel) {
        self.panel = panel
    }

    /// Returns how far the dog moved sideways since the last call, once the
    /// press has become a drag.
    @discardableResult
    func changed() -> CGFloat? {
        guard let panel else { return nil }
        let mouse = NSEvent.mouseLocation
        guard let start = startMouse else {
            startMouse = mouse
            startOrigin = panel.frame.origin
            lastX = mouse.x
            moved = false
            return nil
        }
        let dx = mouse.x - start.x, dy = mouse.y - start.y
        if abs(dx) > Self.clickSlop || abs(dy) > Self.clickSlop { moved = true }
        guard moved else { return nil }
        panel.setFrameOrigin(CGPoint(x: startOrigin.x + dx, y: startOrigin.y + dy))
        defer { lastX = mouse.x }
        return mouse.x - lastX
    }

    /// Returns true when the press was a click rather than a drag.
    func ended() -> Bool {
        defer { startMouse = nil }
        if moved { panel?.dragEnded() }
        return !moved
    }
}
