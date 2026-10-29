import Foundation

/// A finished turn worth a "¡Saltado!" bubble.
public struct TurnFinished: Equatable, Sendable {
    public let sessionId: String
    public let name: String
    public let dish: String
    public let duration: TimeInterval
    public let ok: Bool
    /// Long turns stay on screen until clicked, like the mod's sticky alert.
    public let sticky: Bool

    public init(sessionId: String, name: String, dish: String, duration: TimeInterval, ok: Bool, sticky: Bool) {
        self.sessionId = sessionId
        self.name = name
        self.dish = dish
        self.duration = duration
        self.ok = ok
        self.sticky = sticky
    }
}

public let stickyAfter: TimeInterval = 120

/// Compares each read of the sessions with the previous one and reports the
/// turns that just finished. Mirrors Lomo-Saltado: no notification for
/// aborted turns, for sessions the mod doesn't cook in, or for sessions that
/// vanished. The first read, and the first sight of any session, is a baseline.
public struct TurnWatcher {
    private var last: [String: Session]?

    public init() {}

    public mutating func update(_ sessions: [Session]) -> [TurnFinished] {
        defer { last = Dictionary(sessions.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }
        guard let last else { return [] }
        return sessions.compactMap { now in
            guard let before = last[now.id], now.hasCocina, !now.isCooking, !now.aborted,
                  let started = now.startedAt, let ended = now.endedAt else { return nil }
            let finishedNow = before.isCooking || ended > (before.endedAt ?? .distantPast)
            guard finishedNow else { return nil }
            let duration = ended.timeIntervalSince(started)
            return TurnFinished(sessionId: now.id, name: now.name, dish: bubbleText(now.dish ?? ""),
                                duration: duration, ok: now.errors == 0, sticky: duration > stickyAfter)
        }
    }
}

/// Bubbles shown one at a time, first in first out. A non-sticky one hides
/// itself after `visibleFor`; a sticky one waits for a click.
public struct NotificationQueue {
    public static let visibleFor: TimeInterval = 6

    public private(set) var current: TurnFinished?
    private var waiting: [TurnFinished] = []
    private var shownAt = Date.distantPast

    public init() {}

    public mutating func push(_ turns: [TurnFinished], now: Date) {
        waiting.append(contentsOf: turns)
        if current == nil { showNext(now: now) }
    }

    public mutating func advance(now: Date) {
        guard let current, !current.sticky, now.timeIntervalSince(shownAt) >= Self.visibleFor else { return }
        showNext(now: now)
    }

    public mutating func dismiss(now: Date) {
        showNext(now: now)
    }

    /// Drops the bubble on screen and every one still waiting.
    public mutating func clear() {
        waiting.removeAll()
        current = nil
    }

    private mutating func showNext(now: Date) {
        current = waiting.isEmpty ? nil : waiting.removeFirst()
        shownAt = now
    }
}

/// One line of at most `limit` characters (grapheme clusters, so emoji are
/// never split), with "…" when cut.
public func bubbleText(_ text: String, limit: Int = 60) -> String {
    let flat = text.split(whereSeparator: \.isWhitespace).joined(separator: " ")
    guard flat.count > limit else { return flat }
    return String(flat.prefix(limit - 1)) + "…"
}
