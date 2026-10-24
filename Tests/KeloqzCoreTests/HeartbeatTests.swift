import Foundation
import Testing
@testable import KeloqzCore

private func tempFile() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("keloqz-\(UUID().uuidString)/saltado/keloqz.json")
}

@Test func writesExpectedJson() throws {
    let url = tempFile()
    try HeartbeatFile(url: url).write(pid: 4242, now: Date(timeIntervalSince1970: 1_792_780_000), muted: false,
                                      sessions: ["e245b554", "22cc8fde"])
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    #expect(object?["pid"] as? Int == 4242)
    #expect(object?["updatedAt"] as? Int == 1_792_780_000_000)
    #expect(object?["muted"] as? Bool == false)
    // the mod only skips its banner for sessions listed here
    #expect(object?["sessions"] as? [String] == ["e245b554", "22cc8fde"])
}

@Test func writeCreatesParentDirectory() throws {
    let url = tempFile()
    #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
    try HeartbeatFile(url: url).write(pid: 1, now: Date(), muted: true, sessions: [])
    #expect(FileManager.default.fileExists(atPath: url.path))
}

@Test func removeDeletesFile() throws {
    let url = tempFile()
    let file = HeartbeatFile(url: url)
    try file.write(pid: 1, now: Date(), muted: false, sessions: [])
    file.remove()
    #expect(!FileManager.default.fileExists(atPath: url.path))
}

@Test func coveredSessionsAreTheOnesWithAKitchenRow() {
    let t = Date(timeIntervalSince1970: 1_792_780_000)
    func session(_ id: String, cocina: Bool) -> Session {
        Session(id: id, pid: 1, name: id, cwd: "/w", isCLI: true, hasCocina: cocina, isCooking: false, dish: nil,
                activity: nil, startedAt: nil, endedAt: nil, updatedAt: t, ops: 0, errors: 0, aborted: false)
    }
    #expect(coveredSessionIds([session("a", cocina: true), session("b", cocina: false), session("c", cocina: true)]) == ["a", "c"])
}
