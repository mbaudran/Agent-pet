import Foundation
import Testing
@testable import KeloqzCore

private let fixtures = Bundle.module.url(forResource: "Fixtures", withExtension: nil)!

private func files(_ sub: String) -> [Data] {
    let dir = fixtures.appendingPathComponent(sub)
    let names = (try? FileManager.default.contentsOfDirectory(atPath: dir.path)) ?? []
    return names.sorted().compactMap { try? Data(contentsOf: dir.appendingPathComponent($0)) }
}

private let registry = files("sessions")
private let cocinaWithBroken = files("saltado/cocina")
private let cocina = cocinaWithBroken.filter { String(decoding: $0, as: UTF8.self) != #"{"sessionId":"# }
private let everyoneAlive: (Int32) -> Bool = { _ in true }

private func json(_ object: [String: Any]) -> Data {
    try! JSONSerialization.data(withJSONObject: object)
}

@Test func mergesCocinaOverRegistry() {
    let sessions = SessionMerge.merge(registry: registry, cocina: cocina, isAlive: everyoneAlive)
    let chaska = sessions.first { $0.id.hasPrefix("16a2a5dd") }!
    #expect(chaska.name == "chaska-nawi")
    #expect(chaska.isCooking == false)
    #expect(chaska.dish == "close the server")
    #expect(chaska.ops == 1)
    #expect(chaska.pid == 24945)
    #expect(chaska.hasCocina)
    #expect(chaska.isCLI)
    #expect(chaska.endedAt == Date(timeIntervalSince1970: 1_792_780_076.750))
}

@Test func dropsDeadPids() {
    let sessions = SessionMerge.merge(registry: registry, cocina: cocina, isAlive: { $0 != 24945 })
    #expect(sessions.count == 2)
    #expect(!sessions.contains { $0.id.hasPrefix("16a2a5dd") })
}

@Test func registryOnlySessionUsesBusyStatus() {
    let entry = json(["pid": 999, "sessionId": "solo-1234", "cwd": "/work/solo", "name": "solo",
                      "status": "busy", "entrypoint": "desktop", "updatedAt": 1_792_780_000_000])
    let sessions = SessionMerge.merge(registry: [entry], cocina: [], isAlive: everyoneAlive)
    #expect(sessions.count == 1)
    #expect(sessions[0].isCooking)
    #expect(sessions[0].hasCocina == false)
    #expect(sessions[0].isCLI == false)
    #expect(sessions[0].name == "solo")
}

@Test func skipsBrokenJson() {
    let clean = SessionMerge.merge(registry: registry, cocina: cocina, isAlive: everyoneAlive)
    let withBroken = SessionMerge.merge(registry: registry, cocina: cocinaWithBroken, isAlive: everyoneAlive)
    #expect(cocinaWithBroken.count == cocina.count + 1)
    #expect(clean == withBroken)
}

@Test func duplicateNamesGetShortIdSuffix() {
    let names = SessionMerge.merge(registry: registry, cocina: cocina, isAlive: everyoneAlive).map(\.name)
    #expect(names.contains("PRJ_P · e245"))
    #expect(names.contains("PRJ_P · 22cc"))
    #expect(names.contains("chaska-nawi"))
}

@Test func sortsCookingFirst() {
    let sessions = SessionMerge.merge(registry: registry, cocina: cocina, isAlive: everyoneAlive)
    #expect(sessions.first?.id.hasPrefix("e245b554") == true)
    #expect(sessions.first?.isCooking == true)
    // then most recently finished: 22cc ended after 16a2
    #expect(sessions.map { String($0.id.prefix(4)) } == ["e245", "22cc", "16a2"])
}

@Test func readerReadsDirectories() {
    let sessions = SessionReader(claudeDir: fixtures).read(isAlive: everyoneAlive)
    #expect(sessions.count == 3)
}
