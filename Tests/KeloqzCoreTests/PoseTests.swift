import Foundation
import Testing
@testable import KeloqzCore

private let now = Date(timeIntervalSince1970: 1_792_780_000)

struct PoseCase: Sendable, CustomTestStringConvertible {
    let notifiedAgo: TimeInterval?
    let cooking: Bool
    let activeAgo: TimeInterval
    let expected: Pose
    var testDescription: String { "notified \(notifiedAgo.map { "\($0)s" } ?? "never"), cooking \(cooking), active \(activeAgo)s → \(expected)" }
}

@Test(arguments: [
    PoseCase(notifiedAgo: 0.5, cooking: false, activeAgo: 0, expected: .done),
    PoseCase(notifiedAgo: 1.9, cooking: true, activeAgo: 0, expected: .done),
    PoseCase(notifiedAgo: 2, cooking: false, activeAgo: 0, expected: .idle),
    PoseCase(notifiedAgo: nil, cooking: true, activeAgo: 0, expected: .play),
    PoseCase(notifiedAgo: nil, cooking: true, activeAgo: 600, expected: .play),
    PoseCase(notifiedAgo: nil, cooking: false, activeAgo: 299, expected: .idle),
    PoseCase(notifiedAgo: nil, cooking: false, activeAgo: 300, expected: .sleep),
    PoseCase(notifiedAgo: 900, cooking: false, activeAgo: 900, expected: .sleep),
])
func choosesPose(_ c: PoseCase) {
    let pose = choosePose(lastNotificationAt: c.notifiedAgo.map { now - $0 }, anyCooking: c.cooking,
                          lastActivityAt: now - c.activeAgo, now: now)
    #expect(pose == c.expected)
}

@Test func loadsBundledSpriteInfo() throws {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/Keloqz/Resources/sprites/sprites.json")
    let info = try loadSpriteInfo(Data(contentsOf: url))
    #expect(info[.idle]?.frames == 154)
    #expect(info[.play]?.width == 64)
    #expect(info[.sleep]?.height == 48)
    #expect(Set(info.keys) == Set(Pose.allCases))
}

@Test func missingPoseThrows() {
    let partial = Data(#"{"idle":{"frames":1,"width":48,"height":48,"fps":2}}"#.utf8)
    #expect(throws: (any Error).self) { try loadSpriteInfo(partial) }
}
