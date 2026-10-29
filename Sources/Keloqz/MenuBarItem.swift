import AppKit
import Combine

/// Where Keloqz waits while minimized: 🐾 in the menu bar, with how many
/// sessions are cooking. A click brings the dog back.
@MainActor
final class MenuBarItem: NSObject {
    private let model: AppModel
    private var item: NSStatusItem?
    private var observers: [AnyCancellable] = []

    init(model: AppModel) {
        self.model = model
        super.init()
        model.$sessions.sink { [weak self] _ in
            DispatchQueue.main.async { self?.updateTitle() }
        }.store(in: &observers)
    }

    func setVisible(_ visible: Bool) {
        if visible, item == nil {
            let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
            item.button?.target = self
            item.button?.action = #selector(restore)
            item.button?.toolTip = "Mostrar Keloqz"
            self.item = item
            updateTitle()
        } else if !visible, let item {
            NSStatusBar.system.removeStatusItem(item)
            self.item = nil
        }
    }

    private func updateTitle() {
        let cooking = model.cookingCount
        item?.button?.title = cooking > 0 ? "🐾 \(cooking)" : "🐾"
    }

    @objc private func restore() {
        model.restore()
    }
}
