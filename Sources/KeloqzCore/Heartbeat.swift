import Foundation

/// `~/.claude/saltado/keloqz.json`: tells Lomo-Saltado that Keloqz is up and
/// delivers the finish notifications, so the mod skips its macOS banner.
/// A missing or stale file brings the banners back.
public struct HeartbeatFile {
    public static let interval: TimeInterval = 10

    let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func write(pid: Int32, now: Date, muted: Bool) throws {
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        let beat: [String: Any] = ["pid": Int(pid), "updatedAt": Int((now.timeIntervalSince1970 * 1000).rounded()), "muted": muted]
        try JSONSerialization.data(withJSONObject: beat, options: [.sortedKeys]).write(to: url, options: .atomic)
    }

    public func remove() {
        try? FileManager.default.removeItem(at: url)
    }
}
