import SwiftUI

struct ServeSideIndicatorView: View {
    let totalPoints: Int
    let isMatchOver: Bool

    var body: some View {
        if !isMatchOver {
            let serveRight = totalPoints % 2 == 0

            HStack(spacing: 12) {
                if !serveRight {
                    Image(systemName: "arrow.left")
                        .font(.system(size: 48))
                        .foregroundColor(GoldColor)
                }
                Image(systemName: "tennisball.fill")
                    .font(.system(size: 44))
                    .foregroundColor(GoldColor)
                Text(serveRight ? "RIGHT" : "LEFT")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(GoldColor)
                if serveRight {
                    Image(systemName: "arrow.right")
                        .font(.system(size: 48))
                        .foregroundColor(GoldColor)
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(ButtonBg)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .transition(.scale.combined(with: .opacity))
            .animation(.easeInOut(duration: 0.2), value: serveRight)
        }
    }
}
