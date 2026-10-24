import Foundation

/// One row of the session list, as text.
public struct SessionRow: Equatable, Sendable {
    public let glyph: String
    public let name: String
    public let status: String
    public let detail: String?
}

public func sessionRow(_ s: Session, now: Date) -> SessionRow {
    if s.isCooking {
        let elapsed = s.startedAt.map { " · " + formatDuration(now.timeIntervalSince($0)) } ?? ""
        let ops = s.hasCocina ? " · \(s.ops) ops" : ""
        return SessionRow(glyph: "●", name: s.name, status: "cocinando\(elapsed)\(ops)",
                          detail: s.activity.map { "▸ \($0)" } ?? s.dish)
    }
    if let ended = s.endedAt {
        let ago = formatAgo(now.timeIntervalSince(ended))
        let status = s.aborted ? "parado hace \(ago)" : "servido hace \(ago) \(s.errors == 0 ? "✅" : "❌")"
        return SessionRow(glyph: "✓", name: s.name, status: status, detail: s.dish)
    }
    return SessionRow(glyph: "○", name: s.name, status: "en espera", detail: s.dish)
}

/// "30s", "4m", "2h" — how long ago, coarse.
public func formatAgo(_ seconds: TimeInterval) -> String {
    let total = max(0, Int(seconds.rounded()))
    if total < 60 { return "\(total)s" }
    if total < 3600 { return "\(total / 60)m" }
    return "\(total / 3600)h"
}
