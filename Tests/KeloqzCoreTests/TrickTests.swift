import Foundation
import Testing
@testable import KeloqzCore

private let start = Date(timeIntervalSince1970: 1_792_780_000)

@Test func ballEatPeeTwentySecondsEach() {
    var tricks = TrickSchedule(now: start)
    #expect(tricks.update(awake: true, now: start + 19) == nil)
    #expect(tricks.update(awake: true, now: start + 20) == .eat)
    #expect(tricks.endsAt == start + 40)
    #expect(tricks.update(awake: true, now: start + 39) == .eat)
    #expect(tricks.update(awake: true, now: start + 40) == .pee)
    #expect(tricks.endsAt == start + 60)
    #expect(tricks.update(awake: true, now: start + 60) == nil)
    #expect(tricks.endsAt == nil)
    #expect(tricks.update(awake: true, now: start + 79) == nil)
    #expect(tricks.update(awake: true, now: start + 80) == .eat)
}

@Test func peeFollowsEvenIfKeloqzFellAsleepWhileEating() {
    var tricks = TrickSchedule(now: start)
    #expect(tricks.update(awake: true, now: start + 20) == .eat)
    #expect(tricks.update(awake: false, now: start + 40) == .pee)
}

@Test func sleepingOrBeingDraggedPushesTheBreakBack() {
    var tricks = TrickSchedule(now: start)
    #expect(tricks.update(awake: false, now: start + 50) == nil)
    #expect(tricks.update(awake: true, now: start + 69) == nil)
    #expect(tricks.update(awake: true, now: start + 70) == .eat)
}

@Test func askedForTrickPlaysAloneForAPhase() {
    var tricks = TrickSchedule(now: start)
    tricks.perform(.run, now: start + 5)
    #expect(tricks.update(awake: false, now: start + 24) == .run)
    #expect(tricks.update(awake: true, now: start + 25) == nil)
}

@Test func routineStripsFitOnePhase() throws {
    let url = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/Keloqz/Resources/sprites/sprites.json")
    let info = try loadSpriteInfo(Data(contentsOf: url))
    // eat loops cleanly inside a phase; pee is drawn as exactly one phase
    for pose in TrickSchedule.routine {
        let loop = Double(info[pose]!.frames) / info[pose]!.fps
        #expect(TrickSchedule.phase.truncatingRemainder(dividingBy: loop) == 0, "\(pose) loop \(loop) s")
    }
}
