import Foundation
import ServiceManagement

/// "Abrir al iniciar sesión", through the system login items.
enum LoginItem {
    static var isEnabled: Bool { SMAppService.mainApp.status == .enabled }

    static func set(_ on: Bool) {
        do {
            if on { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
        } catch {
            NSLog("Keloqz: login item \(on ? "register" : "unregister") failed: \(error)")
        }
    }

    /// On by default: turned on once, the first time Keloqz runs as an app.
    static func setUpOnFirstLaunch() {
        let defaults = UserDefaults.standard
        guard Bundle.main.bundleURL.pathExtension == "app", !defaults.bool(forKey: "didSetUpLoginItem") else { return }
        defaults.set(true, forKey: "didSetUpLoginItem")
        set(true)
    }
}
