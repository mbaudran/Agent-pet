import Foundation

/// One live Claude Code session, merged from Claude Code's own registry
/// (`~/.claude/sessions/<pid>.json`) and Lomo-Saltado's kitchen row
/// (`~/.claude/saltado/cocina/<sessionId>.json`).
public struct Session: Equatable, Sendable {
    public let id: String
    public let pid: Int32
    public var name: String
    public let cwd: String
    /// The registry's `entrypoint` is "cli" (a terminal session, not the desktop app).
    public let isCLI: Bool
    public let hasCocina: Bool
    public var isCooking: Bool
    public var dish: String?
    public var activity: String?
    public var startedAt: Date?
    public var endedAt: Date?
    public var updatedAt: Date
    public var ops: Int
    public var errors: Int
    public var aborted: Bool
}

private struct RegistryFile: Decodable {
    let pid: Int32
    let sessionId: String
    let cwd: String?
    let name: String?
    let status: String?
    let entrypoint: String?
    let updatedAt: Double?
}

private struct CocinaFile: Decodable {
    let sessionId: String
    let name: String?
    let cwd: String?
    let phase: String?
    let dish: String?
    let activity: String?
    let startedAt: Double?
    let endedAt: Double?
    let ops: Int?
    let errors: Int?
    let aborted: Bool?
    let updatedAt: Double?
}

private func date(_ ms: Double?) -> Date? {
    guard let ms, ms > 0 else { return nil }
    return Date(timeIntervalSince1970: ms / 1000)
}

private func nonEmpty(_ text: String?) -> String? {
    guard let text, !text.isEmpty else { return nil }
    return text
}

public enum SessionMerge {
    /// Joins both sources on sessionId, drops dead pids and unreadable files,
    /// disambiguates colliding names, and sorts cooking → recently finished → name.
    public static func merge(registry: [Data], cocina: [Data], isAlive: (Int32) -> Bool) -> [Session] {
        let decoder = JSONDecoder()
        let kitchen = Dictionary(
            cocina.compactMap { try? decoder.decode(CocinaFile.self, from: $0) }.map { ($0.sessionId, $0) },
            uniquingKeysWith: { a, b in (a.updatedAt ?? 0) >= (b.updatedAt ?? 0) ? a : b }
        )
        var seen = Set<String>()
        var sessions: [Session] = []
        for entry in registry.compactMap({ try? decoder.decode(RegistryFile.self, from: $0) }) {
            guard isAlive(entry.pid), seen.insert(entry.sessionId).inserted else { continue }
            let row = kitchen[entry.sessionId]
            let cwd = nonEmpty(row?.cwd) ?? entry.cwd ?? ""
            sessions.append(Session(
                id: entry.sessionId,
                pid: entry.pid,
                name: nonEmpty(row?.name) ?? nonEmpty(entry.name) ?? (cwd as NSString).lastPathComponent,
                cwd: cwd,
                isCLI: entry.entrypoint == "cli",
                hasCocina: row != nil,
                isCooking: row.map { $0.phase == "cooking" } ?? (entry.status == "busy"),
                dish: nonEmpty(row?.dish),
                activity: nonEmpty(row?.activity),
                startedAt: date(row?.startedAt),
                endedAt: date(row?.endedAt),
                updatedAt: date(row?.updatedAt) ?? date(entry.updatedAt) ?? .distantPast,
                ops: row?.ops ?? 0,
                errors: row?.errors ?? 0,
                aborted: row?.aborted ?? false
            ))
        }

        let counts = Dictionary(sessions.map { ($0.name, 1) }, uniquingKeysWith: +)
        for i in sessions.indices where counts[sessions[i].name, default: 0] > 1 {
            sessions[i].name += " · \(sessions[i].id.prefix(4))"
        }

        return sessions.sorted { a, b in
            if a.isCooking != b.isCooking { return a.isCooking }
            let ea = a.endedAt ?? .distantPast, eb = b.endedAt ?? .distantPast
            if ea != eb { return ea > eb }
            return a.name < b.name
        }
    }
}

/// Reads both session directories under a `.claude` directory.
public struct SessionReader {
    let claudeDir: URL

    public init(claudeDir: URL) {
        self.claudeDir = claudeDir
    }

    public func read(isAlive: (Int32) -> Bool = pidIsAlive) -> [Session] {
        SessionMerge.merge(
            registry: jsonFiles(in: claudeDir.appendingPathComponent("sessions")),
            cocina: jsonFiles(in: claudeDir.appendingPathComponent("saltado/cocina")),
            isAlive: isAlive
        )
    }

    private func jsonFiles(in dir: URL) -> [Data] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
        return names.filter { $0.hasSuffix(".json") }.compactMap { try? Data(contentsOf: dir.appendingPathComponent($0)) }
    }
}

/// True while a process with this pid exists (EPERM still means it exists).
public func pidIsAlive(_ pid: Int32) -> Bool {
    kill(pid, 0) == 0 || errno == EPERM
}
