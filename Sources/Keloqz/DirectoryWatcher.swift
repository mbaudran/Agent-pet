import CoreServices
import Foundation

/// Calls `onChange` on the main queue when files under `paths` change (FSEvents,
/// coalesced over 0.2 s), and at least every `fallback` seconds in case an
/// event is missed or a watched directory doesn't exist yet.
final class DirectoryWatcher {
    private var stream: FSEventStreamRef?
    private var timer: Timer?
    private let onChange: () -> Void

    init(paths: [URL], fallback: TimeInterval = 3, onChange: @escaping () -> Void) {
        self.onChange = onChange
        let existing = paths.map(\.path).filter { FileManager.default.fileExists(atPath: $0) }
        if !existing.isEmpty {
            var context = FSEventStreamContext(version: 0, info: Unmanaged.passUnretained(self).toOpaque(),
                                               retain: nil, release: nil, copyDescription: nil)
            let callback: FSEventStreamCallback = { _, info, _, _, _, _ in
                guard let info else { return }
                Unmanaged<DirectoryWatcher>.fromOpaque(info).takeUnretainedValue().onChange()
            }
            stream = FSEventStreamCreate(nil, callback, &context, existing as CFArray,
                                         FSEventStreamEventId(kFSEventStreamEventIdSinceNow), 0.2,
                                         FSEventStreamCreateFlags(kFSEventStreamCreateFlagFileEvents | kFSEventStreamCreateFlagNoDefer))
            if let stream {
                FSEventStreamSetDispatchQueue(stream, .main)
                FSEventStreamStart(stream)
            }
        }
        let timer = Timer(timeInterval: fallback, repeats: true) { [weak self] _ in self?.onChange() }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    deinit {
        timer?.invalidate()
        if let stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
        }
    }
}
