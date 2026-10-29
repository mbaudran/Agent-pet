import AppKit
import Combine

/// What the user picks from the right-click menu, kept in UserDefaults.
@MainActor
final class Preferences: ObservableObject {
    static let scales = [2, 3, 4] // S / M / L

    private let defaults = UserDefaults.standard

    @Published var scale: Int {
        didSet { defaults.set(scale, forKey: "scale") }
    }

    @Published var muted: Bool {
        didSet { defaults.set(muted, forKey: "muted") }
    }

    /// Keloqz is hidden and waits in the menu bar.
    @Published var minimized: Bool {
        didSet { defaults.set(minimized, forKey: "minimized") }
    }

    var panelOrigin: CGPoint? {
        get {
            guard let xy = defaults.array(forKey: "panelOrigin") as? [Double], xy.count == 2 else { return nil }
            return CGPoint(x: xy[0], y: xy[1])
        }
        set { defaults.set(newValue.map { [Double($0.x), Double($0.y)] }, forKey: "panelOrigin") }
    }

    init() {
        let saved = defaults.integer(forKey: "scale")
        scale = Self.scales.contains(saved) ? saved : 2
        muted = defaults.bool(forKey: "muted")
        minimized = defaults.bool(forKey: "minimized")
    }
}
