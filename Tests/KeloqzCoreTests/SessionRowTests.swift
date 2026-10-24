import Foundation
import Testing
@testable import KeloqzCore

private let now = Date(timeIntervalSince1970: 1_792_780_000)

private func session(cooking: Bool, started: TimeInterval? = -192, ended: TimeInterval? = nil, errors: Int = 0,
                     aborted: Bool = false, hasCocina: Bool = true, dish: String? = "close the server",
                     activity: String? = "Escribiendo la spec") -> Session {
    Session(id: "s", pid: 1, name: "PRJ_P", cwd: "/w", isCLI: true, hasCocina: hasCocina, isCooking: cooking,
            dish: dish, activity: activity, startedAt: started.map { now + $0 }, endedAt: ended.map { now + $0 },
            updatedAt: now, ops: 14, errors: errors, aborted: aborted)
}

@Test func cookingRow() {
    #expect(sessionRow(session(cooking: true), now: now) ==
        SessionRow(glyph: "●", name: "PRJ_P", status: "cocinando · 3m 12s · 14 ops", detail: "▸ Escribiendo la spec"))
}

@Test func servedRowSaysHowLongAgo() {
    #expect(sessionRow(session(cooking: false, ended: -240), now: now) ==
        SessionRow(glyph: "✓", name: "PRJ_P", status: "servido hace 4m ✅", detail: "close the server"))
}

@Test func servedWithErrorsGetsCross() {
    #expect(sessionRow(session(cooking: false, ended: -30, errors: 1), now: now).status == "servido hace 30s ❌")
}

@Test func abortedRowSaysStopped() {
    #expect(sessionRow(session(cooking: false, ended: -7200, aborted: true), now: now).status == "parado hace 2h")
}

@Test func waitingRow() {
    let row = sessionRow(session(cooking: false, started: nil, hasCocina: false, dish: nil, activity: nil), now: now)
    #expect(row == SessionRow(glyph: "○", name: "PRJ_P", status: "en espera", detail: nil))
}
