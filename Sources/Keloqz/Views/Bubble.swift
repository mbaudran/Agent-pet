import KeloqzCore
import SwiftUI

/// The Codex-style pill above Keloqz: frosted, rounded, white text.
struct Bubble: View {
    let lines: BubbleLines
    let onTap: () -> Void
    /// The ✕ shown while hovering.
    let onClose: () -> Void
    @State private var hovering = false

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(lines.title)
                .font(.system(size: 13, weight: .semibold))
            if let subtitle = lines.subtitle {
                Text(subtitle)
                    .font(.system(size: 13))
                    .opacity(0.85)
            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .foregroundStyle(.white)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(.ultraThinMaterial, in: Capsule())
        .background(Capsule().fill(Color(white: 0.35, opacity: 0.55)))
        .environment(\.colorScheme, .dark)
        .contentShape(Capsule())
        .onTapGesture(perform: onTap)
        .overlay(alignment: .topLeading) {
            if hovering {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(width: 18, height: 18)
                        .background(Circle().fill(Color(white: 0.25)))
                        .overlay(Circle().stroke(Color.white.opacity(0.35), lineWidth: 1))
                        .contentShape(Circle())
                }
                .buttonStyle(.plain)
                .help("Borrar")
                .offset(x: -5, y: -5)
                .transition(.opacity)
            }
        }
        .onHover { hovering = $0 }
    }
}
