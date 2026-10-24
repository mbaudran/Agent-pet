import SwiftUI

/// Sits on Keloqz's shoulder: how many sessions are cooking, and a red dot
/// while a ¡Saltado! hasn't been looked at.
struct Badge: View {
    let cooking: Int
    let hasUnseen: Bool

    var body: some View {
        HStack(spacing: 3) {
            if cooking > 0 {
                Text("\(cooking)")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 1)
                    .background(Capsule().fill(Color(red: 0.36, green: 0.36, blue: 0.94)))
            }
            if hasUnseen {
                Circle().fill(Color.red).frame(width: 8, height: 8)
            }
        }
        .allowsHitTesting(false)
    }
}
