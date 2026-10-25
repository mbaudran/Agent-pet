import KeloqzCore
import SwiftUI

/// Bubble slot, the dog, toolbar slot — the dog anchored at the bottom centre.
struct PetView: View {
    @ObservedObject var model: AppModel
    @ObservedObject var prefs: Preferences
    @ObservedObject var player: SpritePlayer
    @ObservedObject var layout: PanelLayout
    let drag: DragMover

    // Every slot keeps its height whether or not something shows in it, so the
    // dog never moves inside the panel.
    var body: some View {
        VStack(spacing: PetPanel.spacing) {
            VStack(spacing: 4) {
                Spacer(minLength: 0)
                bubble.offset(x: layout.edge.bubbleShift)
                if layout.edge.toolbarAbove { toolbar }
            }
            .frame(width: PetPanel.width, height: PetPanel.bubbleArea)
            dog
            ZStack(alignment: .top) {
                Color.clear
                if !layout.edge.toolbarAbove { toolbar }
            }
            .frame(width: PetPanel.width, height: PetPanel.toolbarHeight)
        }
        .frame(width: PetPanel.width, height: PetPanel.height(scale: prefs.scale), alignment: .bottom)
    }

    @ViewBuilder private var bubble: some View {
        let content = bubbleContent(current: model.current, sessions: model.sessions)
        let visible: Bool = {
            if case .idle = content { return model.isHovering }
            return true
        }()
        if visible {
            Bubble(lines: bubbleLines(content)) { model.dismissBubble() }
                .frame(maxWidth: PetPanel.width - 8)
                .onHover { model.setHovering($0) }
                .transition(.opacity)
        }
    }

    private var dog: some View {
        let scale = CGFloat(prefs.scale)
        return ZStack(alignment: .bottom) {
            if let image = player.image {
                Image(decorative: image, scale: 1)
                    .interpolation(.none)
                    .resizable()
                    .frame(width: CGFloat(player.frameWidth) * scale, height: 48 * scale)
                    .shadow(color: Color(red: 1, green: 0.67, blue: 0.39).opacity(0.32), radius: 8)
            }
        }
        .frame(width: 64 * scale, height: 48 * scale, alignment: .bottom)
        .overlay(alignment: .topTrailing) {
            Badge(cooking: model.cookingCount, hasUnseen: model.hasUnseen)
                .padding(.top, 6 * scale)
                .padding(.trailing, 10 * scale)
        }
        .contentShape(Rectangle())
        .onHover { model.setHovering($0) }
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { _ in drag.changed() }
                .onEnded { _ in
                    if drag.ended() { model.toggleList() }
                }
        )
        .contextMenu { menu }
    }

    @ViewBuilder private var toolbar: some View {
        if model.toolbarVisible {
            Toolbar(model: model, prefs: prefs).transition(.opacity)
        }
    }

    @ViewBuilder private var menu: some View {
        Toggle("Silenciar", isOn: $prefs.muted)
        Picker("Tamaño", selection: $prefs.scale) {
            Text("S").tag(2)
            Text("M").tag(3)
            Text("L").tag(4)
        }
        Toggle("Abrir al iniciar sesión", isOn: Binding(get: { LoginItem.isEnabled }, set: { LoginItem.set($0) }))
        Divider()
        Button("Salir de Keloqz") { NSApp.terminate(nil) }
    }
}
