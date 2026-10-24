import Foundation
import Testing
@testable import KeloqzCore

private func tempFile() -> URL {
    FileManager.default.temporaryDirectory
        .appendingPathComponent("keloqz-\(UUID().uuidString)/saltado/keloqz.json")
}

@Test func writesExpectedJson() throws {
    let url = tempFile()
    try HeartbeatFile(url: url).write(pid: 4242, now: Date(timeIntervalSince1970: 1_792_780_000), muted: false)
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any]
    #expect(object?["pid"] as? Int == 4242)
    #expect(object?["updatedAt"] as? Int == 1_792_780_000_000)
    #expect(object?["muted"] as? Bool == false)
}

@Test func writeCreatesParentDirectory() throws {
    let url = tempFile()
    #expect(!FileManager.default.fileExists(atPath: url.deletingLastPathComponent().path))
    try HeartbeatFile(url: url).write(pid: 1, now: Date(), muted: true)
    #expect(FileManager.default.fileExists(atPath: url.path))
}

@Test func removeDeletesFile() throws {
    let url = tempFile()
    let file = HeartbeatFile(url: url)
    try file.write(pid: 1, now: Date(), muted: false)
    file.remove()
    #expect(!FileManager.default.fileExists(atPath: url.path))
}
