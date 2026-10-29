import SwiftUI

/// Under Keloqz while hovering: 🐾 session list · ＋ new session · 🔕 mute · – minimize.
struct Toolbar: View {
    @ObservedObject var model: AppModel
    @ObservedObject var prefs: Preferences

    var body: some View {
        HStack(spacing: 0) {
            Button { model.toggleList() } label: { segment("🐾") }
                .help("Sesiones")
            divider
            Menu {
                ForEach(model.recentFolders, id: \.self) { dir in
                    Button((dir as NSString).abbreviatingWithTildeInPath) { NewSession.open(in: dir) }
                }
                if !model.recentFolders.isEmpty { Divider() }
                Button("Otra carpeta…") { NewSession.chooseFolder() }
            } label: {
                segment("＋")
            }
            .menuStyle(.borderlessButton)
            .menuIndicator(.hidden)
            .fixedSize()
            .help("Nueva sesión de Claude")
            divider
            Button { model.toggleMute() } label: { segment(prefs.muted ? "🔔" : "🔕") }
                .help(prefs.muted ? "Activar avisos" : "Silenciar")
            divider
            Button { model.minimize() } label: { segment("–") }
                .help("Minimizar a la barra de menús")
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 6)
        .padding(.vertical, 4)
        .background(.ultraThinMaterial, in: Capsule())
        .background(Capsule().fill(Color(white: 0.35, opacity: 0.45)))
        .environment(\.colorScheme, .dark)
        .onHover { model.setHovering($0) }
    }

    private func segment(_ symbol: String) -> some View {
        Text(symbol)
            .font(.system(size: 14))
            .foregroundStyle(.white)
            .frame(width: 34, height: 22)
            .contentShape(Rectangle())
    }

    private var divider: some View {
        Rectangle().fill(Color.white.opacity(0.25)).frame(width: 1, height: 16)
    }
}
