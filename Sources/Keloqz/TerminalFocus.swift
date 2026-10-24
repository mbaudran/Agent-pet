import AppKit
import KeloqzCore

/// Brings a session's Terminal.app tab to the front, found through its tty.
@MainActor
enum TerminalFocus {
    static let terminal = "com.apple.Terminal"
    static let claudeDesktop = "com.anthropic.claudefordesktop"

    static func focus(_ session: Session) {
        guard session.isCLI else { return activate(claudeDesktop) }
        guard let tty = tty(of: session.pid) else { return activate(terminal) }
        let script = """
        tell application "Terminal"
          repeat with w in windows
            repeat with t in tabs of w
              if tty of t is "/dev/\(tty)" then
                set selected of t to true
                set index of w to 1
                activate
                return true
              end if
            end repeat
          end repeat
          activate
        end tell
        """
        var error: NSDictionary?
        NSAppleScript(source: script)?.executeAndReturnError(&error)
        if let error {
            NSLog("Keloqz: focusing Terminal failed: \(error)")
            activate(terminal) // tab gone or Automation denied
        }
    }

    static func activate(_ bundleId: String) {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else { return }
        NSWorkspace.shared.openApplication(at: url, configuration: NSWorkspace.OpenConfiguration())
    }

    /// "ttys003", or nil when the process has no terminal.
    static func tty(of pid: Int32) -> String? {
        let ps = Process()
        ps.executableURL = URL(fileURLWithPath: "/bin/ps")
        ps.arguments = ["-o", "tty=", "-p", String(pid)]
        let pipe = Pipe()
        ps.standardOutput = pipe
        ps.standardError = FileHandle.nullDevice
        guard (try? ps.run()) != nil else { return nil }
        ps.waitUntilExit()
        let tty = String(decoding: pipe.fileHandleForReading.readDataToEndOfFile(), as: UTF8.self)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return tty.isEmpty || tty.hasPrefix("?") ? nil : tty
    }
}

/// Opens a new Terminal tab running `claude` in a folder.
@MainActor
enum NewSession {
    static func open(in dir: String) {
        var error: NSDictionary?
        NSAppleScript(source: newSessionScript(in: dir))?.executeAndReturnError(&error)
        if let error { NSLog("Keloqz: opening a new session failed: \(error)") }
        TerminalFocus.activate(TerminalFocus.terminal)
    }

    static func chooseFolder() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.allowsMultipleSelection = false
        panel.prompt = "Abrir Claude aquí"
        NSApp.activate()
        if panel.runModal() == .OK, let url = panel.url { open(in: url.path) }
    }
}
