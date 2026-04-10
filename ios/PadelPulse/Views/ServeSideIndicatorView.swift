import SwiftUI

struct ServeSideIndicatorView: View {
    let totalPoints: Int
    let isMatchOver: Bool

    @Environment(\.layout) private var layout
    @State private var pulseOpacity: CGFloat = 1.0

    var body: some View {
        if !isMatchOver {
            let serveRight = totalPoints % 2 == 0

            HStack(spacing: 12) {
                if !serveRight {
                    Image(systemName: "arrow.left")
                        .font(.system(size: layout.serveArrowSize))
                        .foregroundColor(GoldColor)
                }
                Image(systemName: "tennisball.fill")
                    .font(.system(size: layout.serveBallSize))
                    .foregroundColor(GoldColor)
                Text(serveRight ? "RIGHT" : "LEFT")
                    .font(.system(size: layout.serveTextSize, weight: .bold))
                    .foregroundColor(GoldColor)
                if serveRight {
                    Image(systemName: "arrow.right")
                        .font(.system(size: layout.serveArrowSize))
                        .foregroundColor(GoldColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(ButtonBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .opacity(pulseOpacity)
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.2), value: serveRight)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(serveRight
                ? Text("Serve from the right side")
                : Text("Serve from the left side"))
            .onChange(of: totalPoints) { _, _ in
                pulseOpacity = 0.5
                withAnimation(.easeInOut(duration: 0.3)) {
                    pulseOpacity = 1.0
                }
            }
        }
    }
}
