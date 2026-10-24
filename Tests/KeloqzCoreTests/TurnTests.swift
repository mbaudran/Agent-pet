import Foundation
import Testing
@testable import KeloqzCore

private let t0 = Date(timeIntervalSince1970: 1_792_780_000)

private func session(
    _ id: String = "s1", cooking: Bool, started: Date? = t0, ended: Date? = nil,
    errors: Int = 0, aborted: Bool = false, hasCocina: Bool = true
) -> Session {
    Session(id: id, pid: 1, name: "chaska-nawi", cwd: "/work", isCLI: true, hasCocina: hasCocina,
            isCooking: cooking, dish: "close the server", activity: nil, startedAt: started, endedAt: ended,
            updatedAt: t0, ops: 3, errors: errors, aborted: aborted)
}

private func turn(_ id: String, sticky: Bool = false) -> TurnFinished {
    TurnFinished(sessionId: id, name: id, dish: "", duration: sticky ? 300 : 10, ok: true, sticky: sticky)
}

@Test func firstUpdateIsBaseline() {
    var watcher = TurnWatcher()
    #expect(watcher.update([session(cooking: false, ended: t0 + 30)]).isEmpty)
}

@Test func cookingToCookedEmits() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true)])
    let turns = watcher.update([session(cooking: false, ended: t0 + 252)])
    #expect(turns == [TurnFinished(sessionId: "s1", name: "chaska-nawi", dish: "close the server",
                                   duration: 252, ok: true, sticky: true)])
}

@Test func newEndedAtWhileCookedEmits() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: false, ended: t0 + 10)])
    let turns = watcher.update([session(cooking: false, started: t0 + 20, ended: t0 + 22)])
    #expect(turns.count == 1)
    #expect(turns.first?.duration == 2)
}

@Test func errorsMakeItNotOk() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true)])
    #expect(watcher.update([session(cooking: false, ended: t0 + 60, errors: 2)]).first?.ok == false)
}

@Test func shortTurnIsNotSticky() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true)])
    #expect(watcher.update([session(cooking: false, ended: t0 + 40)]).first?.sticky == false)
}

@Test func vanishedWhileCookingEmitsNothing() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true)])
    #expect(watcher.update([]).isEmpty)
}

@Test func abortedTurnEmitsNothing() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true)])
    #expect(watcher.update([session(cooking: false, ended: t0 + 5, aborted: true)]).isEmpty)
}

@Test func registryOnlySessionNeverEmits() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true, started: nil, hasCocina: false)])
    #expect(watcher.update([session(cooking: false, started: nil, ended: nil, hasCocina: false)]).isEmpty)
}

@Test func endedAtMissingEmitsNothing() {
    var watcher = TurnWatcher()
    _ = watcher.update([session(cooking: true)])
    #expect(watcher.update([session(cooking: false, ended: nil)]).isEmpty)
}

@Test func newSessionAppearingCookedIsBaseline() {
    var watcher = TurnWatcher()
    _ = watcher.update([])
    #expect(watcher.update([session("resumed", cooking: false, ended: t0 + 9)]).isEmpty)
}

@Test func queueShowsOneAtATimeFifo() {
    var queue = NotificationQueue()
    queue.push([turn("a"), turn("b")], now: t0)
    #expect(queue.current?.sessionId == "a")
    queue.dismiss(now: t0 + 1)
    #expect(queue.current?.sessionId == "b")
    queue.dismiss(now: t0 + 2)
    #expect(queue.current == nil)
}

@Test func nonStickyHidesAfterSixSeconds() {
    var queue = NotificationQueue()
    queue.push([turn("a")], now: t0)
    queue.advance(now: t0 + 5.9)
    #expect(queue.current?.sessionId == "a")
    queue.advance(now: t0 + 6)
    #expect(queue.current == nil)
}

@Test func nextTurnGetsItsOwnSixSeconds() {
    var queue = NotificationQueue()
    queue.push([turn("a"), turn("b")], now: t0)
    queue.advance(now: t0 + 6)
    #expect(queue.current?.sessionId == "b")
    queue.advance(now: t0 + 11.9)
    #expect(queue.current?.sessionId == "b")
}

@Test func stickyStaysUntilDismissed() {
    var queue = NotificationQueue()
    queue.push([turn("a", sticky: true)], now: t0)
    queue.advance(now: t0 + 600)
    #expect(queue.current?.sessionId == "a")
}

@Test func bubbleTextCollapsesAndTruncatesByGrapheme() {
    #expect(bubbleText("a\n\n  b") == "a b")
    #expect(bubbleText(String(repeating: "🐕", count: 70)) == String(repeating: "🐕", count: 59) + "…")
    let sixty = String(repeating: "x", count: 60)
    #expect(bubbleText(sixty) == sixty)
}
