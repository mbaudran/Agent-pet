import Foundation

/// What the bubble above Keloqz is about, in priority order.
public enum BubbleContent: Equatable, Sendable {
    case finished(TurnFinished)
    case cooking(Session, count: Int)
    /// Nothing cooking; only shown while hovering.
    case idle(count: Int)
}

public func bubbleContent(current: TurnFinished?, sessions: [Session]) -> BubbleContent {
    if let current { return .finished(current) }
    let cooking = sessions.filter(\.isCooking)
    if let latest = cooking.max(by: { $0.updatedAt < $1.updatedAt }) {
        return .cooking(latest, count: cooking.count)
    }
    return .idle(count: sessions.count)
}

public struct BubbleLines: Equatable, Sendable {
    public let title: String
    public let subtitle: String?
}

public func bubbleLines(_ content: BubbleContent) -> BubbleLines {
    switch content {
    case .finished(let turn):
        let time = formatDuration(turn.duration)
        return BubbleLines(title: "\(turn.name) — ¡Saltado! \(turn.ok ? "✅" : "❌")",
                           subtitle: turn.dish.isEmpty ? time : "\(turn.dish) · \(time)")
    case .cooking(let session, let count):
        let title = session.dish.map { "\(session.name) — \(bubbleText($0))" } ?? session.name
        let pans = "\(count) 🍳"
        return BubbleLines(title: title, subtitle: session.activity.map { "▸ \(bubbleText($0, limit: 40)) · \(pans)" } ?? pans)
    case .idle(let count):
        switch count {
        case 0: return BubbleLines(title: "Sin sesiones abiertas", subtitle: nil)
        case 1: return BubbleLines(title: "1 sesión · todo servido", subtitle: nil)
        default: return BubbleLines(title: "\(count) sesiones · todo servido", subtitle: nil)
        }
    }
}

/// "41s", "4m 02s", "1h 05m".
public func formatDuration(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    if total < 60 { return "\(total)s" }
    if total < 3600 { return String(format: "%dm %02ds", total / 60, total % 60) }
    return String(format: "%dh %02dm", total / 3600, (total % 3600) / 60)
}
