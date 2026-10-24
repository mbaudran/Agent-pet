import KeloqzCore
import SwiftUI

/// The Codex-style pill above Keloqz: frosted, rounded, white text.
struct Bubble: View {
    let lines: BubbleLines
    let onTap: () -> Void

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
    }
}
