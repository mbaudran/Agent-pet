import Foundation

/// `~/.claude/saltado/keloqz.json`: tells Lomo-Saltado that Keloqz is up and
/// which sessions it delivers the finish notifications for, so the mod skips
/// its macOS banner for those sessions only. A missing or stale file, or a
/// session not listed, brings the banners back.
public struct HeartbeatFile {
    public static let interval: TimeInterval = 10

    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func write(pid: Int32, now: Date, muted: Bool, sessions: [String]) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let beat: [String: Any] = ["pid": Int(pid), "updatedAt": Int((now.timeIntervalSince1970 * 1000).rounded()),
                                   "muted": muted, "sessions": sessions]
        try JSONSerialization.data(withJSONObject: beat, options: [.sortedKeys]).write(to: url, options: .atomic)
    }

    public func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}

/// The sessions Keloqz can announce: the ones with a kitchen row it joined to
/// a live Claude Code session. Only these go in the heartbeat.
public func coveredSessionIds(_ sessions: [Session]) -> [String] {
    sessions.filter(\.hasCocina).map(\.id)
}
