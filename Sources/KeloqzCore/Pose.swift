import Foundation

public enum Pose: String, CaseIterable, Sendable {
    case idle, play, done, sleep, eat, pee, run
}

public let donePoseFor: TimeInterval = 2
public let sleepAfter: TimeInterval = 5 * 60

/// Which animation Keloqz plays. `lastActivityAt` is the latest of the last
/// hover/click and the last moment any session was cooking. He runs while
/// being dragged, and a trick (eat, pee, run) beats everything but ¡Saltado!.
public func choosePose(lastNotificationAt: Date?, anyCooking: Bool, lastActivityAt: Date, now: Date,
                       dragging: Bool = false, trick: Pose? = nil) -> Pose {
    if dragging { return .run }
    if let notified = lastNotificationAt, now.timeIntervalSince(notified) < donePoseFor { return .done }
    if let trick { return trick }
    if anyCooking { return .play }
    if now.timeIntervalSince(lastActivityAt) >= sleepAfter { return .sleep }
    return .idle
}

/// One pose's strip in `sprites.json`, written by tools/render-sprites.mjs.
public struct SpriteSheetInfo: Decodable, Equatable, Sendable {
    public let frames: Int
    public let width: Int
    public let height: Int
    public let fps: Double
}

public struct MissingPose: Error {
    public let pose: Pose
}

public func loadSpriteInfo(_ data: Data) throws -> [Pose: SpriteSheetInfo] {
    let raw = try JSONDecoder().decode([String: SpriteSheetInfo].self, from: data)
    var info: [Pose: SpriteSheetInfo] = [:]
    for pose in Pose.allCases {
        guard let sheet = raw[pose.rawValue] else { throw MissingPose(pose: pose) }
        info[pose] = sheet
    }
    return info
}
