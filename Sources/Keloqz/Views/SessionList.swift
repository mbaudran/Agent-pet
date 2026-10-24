import AppKit
import Combine
import KeloqzCore
import SwiftUI

/// The frosted card beside Keloqz listing every session. It can become key
/// (for Esc) without activating the app, and closes on any click elsewhere.
@MainActor
final class SessionListPanel: NSPanel {
    static let width: CGFloat = 340

    private let model: AppModel
    private var clickMonitor: Any?

    init(model: AppModel) {
        self.model = model
        super.init(contentRect: NSRect(x: 0, y: 0, width: Self.width, height: 100),
                   styleMask: [.borderless, .nonactivatingPanel], backing: .buffered, defer: false)
        level = .floating
        collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .ignoresCycle]
        isOpaque = false
        backgroundColor = .clear
        hasShadow = true
        hidesOnDeactivate = false
        let hosting = FirstMouseHostingView(rootView: SessionListView(model: model))
        hosting.sizingOptions = [.preferredContentSize]
        contentView = hosting
    }

    override var canBecomeKey: Bool { true }

    override func cancelOperation(_ sender: Any?) {
        model.closeList()
    }

    /// Beside the dog, on whichever side has room, bottoms aligned.
    func show(beside pet: NSWindow) {
        layoutIfNeeded()
        let size = contentView?.fittingSize ?? frame.size
        let screen = (pet.screen ?? NSScreen.main ?? NSScreen.screens[0]).visibleFrame
        let dogBottom = pet.frame.minY + PetPanel.toolbarHeight + PetPanel.spacing
        var x = pet.frame.midX - 64 - size.width
        if x < screen.minX { x = pet.frame.midX + 64 }
        let origin = clampedOrigin(CGPoint(x: x, y: dogBottom), size: size, screens: [screen])
        setFrame(NSRect(origin: origin, size: size), display: true)
        makeKeyAndOrderFront(nil)
        clickMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            MainActor.assumeIsolated { self?.model.closeList() }
        }
    }

    func hide() {
        if let clickMonitor { NSEvent.removeMonitor(clickMonitor) }
        clickMonitor = nil
        orderOut(nil)
    }
}

struct SessionListView: View {
    @ObservedObject var model: AppModel

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            VStack(alignment: .leading, spacing: 2) {
                if model.sessions.isEmpty {
                    Text("Sin sesiones abiertas")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                        .padding(10)
                }
                ForEach(model.sessions, id: \.id) { session in
                    SessionRowView(row: sessionRow(session, now: context.date)) {
                        model.closeList()
                        TerminalFocus.focus(session)
                    }
                }
            }
            .padding(6)
        }
        .frame(width: SessionListPanel.width)
        .fixedSize(horizontal: false, vertical: true)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
        .background(RoundedRectangle(cornerRadius: 14).fill(Color(white: 0.2, opacity: 0.5)))
        .environment(\.colorScheme, .dark)
    }
}

private struct SessionRowView: View {
    let row: SessionRow
    let onTap: () -> Void
    @State private var hovering = false

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(row.glyph).foregroundStyle(row.glyph == "●" ? Color.orange : .secondary)
                    Text(row.name).fontWeight(.semibold).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(row.status).foregroundStyle(.secondary).lineLimit(1)
                }
                if let detail = row.detail {
                    Text(bubbleText(detail, limit: 48))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .padding(.leading, 18)
                }
            }
            .font(.system(size: 12))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 8).fill(Color.white.opacity(hovering ? 0.12 : 0)))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
