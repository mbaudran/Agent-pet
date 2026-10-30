import Foundation

/// Keloqz's routine: 20 s playing ball (or sitting, when nothing cooks), 20 s
/// eating from his bowl, 20 s peeing, and round again. Every trick lasts one
/// phase, including the ones asked for from the menu, which play on their own.
public struct TrickSchedule: Sendable {
    public static let phase: TimeInterval = 20
    public static let routine: [Pose] = [.eat, .pee]

    public private(set) var current: Pose?
    public private(set) var endsAt: Date?
    private var nextAt: Date
    /// Where the current trick sits in `routine`; nil for one asked from the menu.
    private var step: Int?

    public init(now: Date) {
        nextAt = now + Self.phase
    }

    public mutating func perform(_ pose: Pose, now: Date) {
        current = pose
        endsAt = now + Self.phase
        step = nil
    }

    /// The trick to show now, if any. `awake`: Keloqz would otherwise play
    /// ball or sit (not sleep, jump or run).
    public mutating func update(awake: Bool, now: Date) -> Pose? {
        if let end = endsAt, now >= end {
            if let step, step + 1 < Self.routine.count {
                start(step + 1, now: now)
            } else {
                current = nil
                endsAt = nil
                step = nil
                nextAt = now + Self.phase
            }
        }
        if current != nil { return current }
        guard awake else {
            nextAt = max(nextAt, now + Self.phase)
            return nil
        }
        if now >= nextAt { start(0, now: now) }
        return current
    }

    private mutating func start(_ index: Int, now: Date) {
        perform(Self.routine[index], now: now)
        step = index
    }
}
