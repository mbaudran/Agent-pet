import Foundation

/// The ＋ menu's folders: newest first, distinct, at most `limit`.
public func mergeRecent(_ existing: [String], adding: [String], limit: Int = 5) -> [String] {
    var seen = Set<String>()
    return (adding + existing).filter { !$0.isEmpty && seen.insert($0).inserted }.prefix(limit).map { $0 }
}

/// A POSIX shell word: wrapped in single quotes, inner quotes as '\''.
public func shellQuote(_ text: String) -> String {
    "'" + text.replacingOccurrences(of: "'", with: #"'\''"#) + "'"
}

/// AppleScript that opens a new Terminal tab running Claude Code in `dir`.
public func newSessionScript(in dir: String) -> String {
    let command = "cd \(shellQuote(dir)) && claude"
    let literal = command.replacingOccurrences(of: "\\", with: "\\\\").replacingOccurrences(of: "\"", with: "\\\"")
    return #"tell application "Terminal" to do script ""# + literal + #"""#
}
