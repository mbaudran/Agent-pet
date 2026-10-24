import Foundation
import Testing
@testable import KeloqzCore

private let t0 = Date(timeIntervalSince1970: 1_792_780_000)

private func cooking(_ name: String, updated: TimeInterval, dish: String? = "Diseñando a Keloqz",
                     activity: String? = "Editando register.tsx") -> Session {
    Session(id: name, pid: 1, name: name, cwd: "/w", isCLI: true, hasCocina: true, isCooking: true,
            dish: dish, activity: activity, startedAt: t0, endedAt: nil, updatedAt: t0 + updated,
            ops: 1, errors: 0, aborted: false)
}

private func served(_ name: String) -> Session {
    var s = cooking(name, updated: 0)
    s.isCooking = false
    return s
}

private let finished = TurnFinished(sessionId: "x", name: "chaska-nawi", dish: "close the server",
                                    duration: 242, ok: true, sticky: true)

@Test func finishedTurnWinsOverCooking() {
    #expect(bubbleContent(current: finished, sessions: [cooking("PRJ_P", updated: 0)]) == .finished(finished))
}

@Test func picksMostRecentlyUpdatedCookingSession() {
    let content = bubbleContent(current: nil, sessions: [cooking("a", updated: 1), cooking("b", updated: 5), served("c")])
    #expect(content == .cooking(cooking("b", updated: 5), count: 2))
}

@Test func nothingCookingIsIdle() {
    #expect(bubbleContent(current: nil, sessions: [served("a"), served("b")]) == .idle(count: 2))
}

@Test func finishedLines() {
    #expect(bubbleLines(.finished(finished)) == BubbleLines(title: "chaska-nawi — ¡Saltado! ✅", subtitle: "close the server · 4m 02s"))
}

@Test func failedTurnUsesCross() {
    let failed = TurnFinished(sessionId: "x", name: "api", dish: "", duration: 41, ok: false, sticky: false)
    #expect(bubbleLines(.finished(failed)) == BubbleLines(title: "api — ¡Saltado! ❌", subtitle: "41s"))
}

@Test func cookingLines() {
    let lines = bubbleLines(.cooking(cooking("PRJ_P", updated: 0), count: 2))
    #expect(lines == BubbleLines(title: "PRJ_P — Diseñando a Keloqz", subtitle: "▸ Editando register.tsx · 2 🍳"))
}

@Test func cookingWithoutDishOrActivity() {
    let lines = bubbleLines(.cooking(cooking("PRJ_P", updated: 0, dish: nil, activity: nil), count: 1))
    #expect(lines == BubbleLines(title: "PRJ_P", subtitle: "1 🍳"))
}

@Test func idleLines() {
    #expect(bubbleLines(.idle(count: 3)) == BubbleLines(title: "3 sesiones · todo servido", subtitle: nil))
    #expect(bubbleLines(.idle(count: 1)) == BubbleLines(title: "1 sesión · todo servido", subtitle: nil))
    #expect(bubbleLines(.idle(count: 0)) == BubbleLines(title: "Sin sesiones abiertas", subtitle: nil))
}

@Test func formatsDurations() {
    #expect(formatDuration(41) == "41s")
    #expect(formatDuration(242) == "4m 02s")
    #expect(formatDuration(3900) == "1h 05m")
}
