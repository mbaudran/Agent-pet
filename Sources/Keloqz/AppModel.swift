import AppKit
import Combine
import KeloqzCore

/// Wires the pieces together: reads sessions, spots finished turns, queues
/// bubbles, picks the pose and keeps the heartbeat Lomo-Saltado listens for.
@MainActor
final class AppModel: ObservableObject {
    @Published private(set) var sessions: [Session] = []
    @Published private(set) var current: TurnFinished?
    @Published private(set) var hasUnseen = false
    @Published private(set) var isHovering = false

    let prefs: Preferences
    let player: SpritePlayer

    private let claudeDir: URL
    private let reader: SessionReader
    private let heartbeat: HeartbeatFile
    private var turns = TurnWatcher()
    private var queue = NotificationQueue()
    private var lastNotificationAt: Date?
    private var lastActivityAt = Date()
    private var watcher: DirectoryWatcher?
    private var timers: [Timer] = []
    private var observers: [AnyCancellable] = []

    var cookingCount: Int { sessions.filter(\.isCooking).count }

    init(prefs: Preferences, player: SpritePlayer,
         claudeDir: URL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent(".claude")) {
        self.prefs = prefs
        self.player = player
        self.claudeDir = claudeDir
        reader = SessionReader(claudeDir: claudeDir)
        heartbeat = HeartbeatFile(url: claudeDir.appendingPathComponent("saltado/keloqz.json"))
    }

    func start() {
        refresh()
        watcher = DirectoryWatcher(paths: [claudeDir.appendingPathComponent("sessions"),
                                           claudeDir.appendingPathComponent("saltado/cocina")]) { [weak self] in
            MainActor.assumeIsolated { self?.refresh() }
        }
        every(1) { $0.tick() }
        writeHeartbeat()
        every(HeartbeatFile.interval) { $0.writeHeartbeat() }
        prefs.$muted.dropFirst().sink { [weak self] _ in
            DispatchQueue.main.async { self?.writeHeartbeat() }
        }.store(in: &observers)
    }

    func stop() {
        heartbeat.remove()
    }

    func refresh() {
        let now = Date()
        sessions = reader.read()
        let finished = turns.update(sessions)
        if sessions.contains(where: \.isCooking) { lastActivityAt = now }
        if !finished.isEmpty, !prefs.muted {
            queue.push(finished, now: now)
            current = queue.current
            hasUnseen = true
            lastNotificationAt = now
            NSSound(named: "Ping")?.play()
        }
        updatePose(now: now)
    }

    func dismissBubble() {
        queue.dismiss(now: Date())
        current = queue.current
        hasUnseen = false
    }

    func noteActivity() {
        lastActivityAt = Date()
        updatePose(now: lastActivityAt)
    }

    func setHovering(_ hovering: Bool) {
        isHovering = hovering
        if hovering { noteActivity() }
    }

    func toggleMute() {
        prefs.muted.toggle()
    }

    private func tick() {
        let now = Date()
        queue.advance(now: now)
        if current != queue.current { current = queue.current }
        updatePose(now: now)
    }

    private func updatePose(now: Date) {
        player.play(choosePose(lastNotificationAt: lastNotificationAt, anyCooking: sessions.contains(where: \.isCooking),
                               lastActivityAt: lastActivityAt, now: now))
    }

    private func writeHeartbeat() {
        do {
            try heartbeat.write(pid: ProcessInfo.processInfo.processIdentifier, now: Date(), muted: prefs.muted)
        } catch {
            NSLog("Keloqz: heartbeat write failed: \(error)") // the mod falls back to banners
        }
    }

    private func every(_ seconds: TimeInterval, _ action: @escaping (AppModel) -> Void) {
        let timer = Timer(timeInterval: seconds, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { if let self { action(self) } }
        }
        RunLoop.main.add(timer, forMode: .common)
        timers.append(timer)
    }
}
