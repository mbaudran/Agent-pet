import AppKit

@main
enum KeloqzMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // no Dock icon, no Cmd+Tab
        // `pkill Keloqz` quits like the menu does, so the heartbeat file is removed.
        signal(SIGTERM, SIG_IGN)
        let sigterm = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigterm.setEventHandler { NSApp.terminate(nil) }
        sigterm.resume()
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let prefs = Preferences()
    private var model: AppModel!
    private var panel: PetPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        // KELOQZ_CLAUDE_DIR points a test copy at fake session files instead of ~/.claude.
        if let dir = ProcessInfo.processInfo.environment["KELOQZ_CLAUDE_DIR"] {
            model = AppModel(prefs: prefs, player: SpritePlayer(), claudeDir: URL(fileURLWithPath: dir))
        } else {
            model = AppModel(prefs: prefs, player: SpritePlayer())
        }
        LoginItem.setUpOnFirstLaunch()
        panel = PetPanel(model: model)
        panel.show()
        model.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        model?.stop() // banners come back right away
    }
}
