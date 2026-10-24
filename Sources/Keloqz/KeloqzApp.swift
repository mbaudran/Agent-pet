import AppKit

@main
enum KeloqzMain {
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.setActivationPolicy(.accessory) // no Dock icon, no Cmd+Tab
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let prefs = Preferences()
    private var player: SpritePlayer!
    private var panel: PetPanel!

    func applicationDidFinishLaunching(_ notification: Notification) {
        player = SpritePlayer()
        LoginItem.setUpOnFirstLaunch()
        panel = PetPanel(prefs: prefs, player: player)
        panel.show()
        player.play(.idle)
    }
}
