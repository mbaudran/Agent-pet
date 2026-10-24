import KeloqzCore
import SwiftUI

/// Bubble slot, the dog, toolbar slot — the dog anchored at the bottom centre.
struct PetView: View {
    @ObservedObject var prefs: Preferences
    @ObservedObject var player: SpritePlayer
    let drag: DragMover

    var body: some View {
        VStack(spacing: PetPanel.spacing) {
            Color.clear.frame(height: PetPanel.bubbleHeight)
            dog
            Color.clear.frame(height: PetPanel.toolbarHeight)
        }
        .frame(width: PetPanel.width)
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
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { _ in drag.changed() }
                .onEnded { _ in _ = drag.ended() }
        )
        .contextMenu { menu }
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
