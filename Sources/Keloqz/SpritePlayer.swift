import AppKit
import ImageIO
import KeloqzCore

/// Plays the pre-rendered strips from Resources/sprites (tools/render-sprites.mjs).
/// It only plays the pose it is given; choosing the pose happens elsewhere.
@MainActor
final class SpritePlayer: ObservableObject {
    @Published private(set) var image: CGImage?
    @Published private(set) var pose: Pose = .idle

    private let strips: [Pose: CGImage]
    private let info: [Pose: SpriteSheetInfo]
    private var frame = 0
    private var timer: Timer?

    var frameWidth: Int { info[pose]!.width }

    init() {
        guard let dir = Bundle.module.url(forResource: "sprites", withExtension: nil),
              let data = try? Data(contentsOf: dir.appendingPathComponent("sprites.json")),
              let info = try? loadSpriteInfo(data)
        else { fatalError("Keloqz: sprites.json missing or unreadable in the app bundle") }
        var strips: [Pose: CGImage] = [:]
        for pose in Pose.allCases {
            let url = dir.appendingPathComponent("\(pose.rawValue).png")
            guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
                  let strip = CGImageSourceCreateImageAtIndex(source, 0, nil)
            else { fatalError("Keloqz: \(pose.rawValue).png missing in the app bundle") }
            strips[pose] = strip
        }
        self.info = info
        self.strips = strips
    }

    /// Restarts at frame 0 only when the pose changes.
    func play(_ pose: Pose) {
        guard pose != self.pose || timer == nil else { return }
        self.pose = pose
        frame = 0
        show()
        timer?.invalidate()
        let timer = Timer(timeInterval: 1 / info[pose]!.fps, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func tick() {
        frame = (frame + 1) % info[pose]!.frames
        show()
    }

    private func show() {
        let sheet = info[pose]!
        image = strips[pose]!.cropping(to: CGRect(x: frame * sheet.width, y: 0, width: sheet.width, height: sheet.height))
    }
}
