import SwiftUI

struct OnboardingOverlayView: View {
    let onDismiss: () -> Void

    @Environment(\.layout) private var layout

    var body: some View {
        ZStack {
            Color.black.opacity(0.88)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Text("PADEL PULSE")
                    .font(.system(size: layout.matchOverTitleFont, weight: .bold))
                    .foregroundColor(GoldColor)
                    .tracking(4)

                VStack(alignment: .leading, spacing: 20) {
                    hintRow(icon: "hand.tap", text: "Tap left or right side to score a point")
                    hintRow(icon: "arrow.uturn.backward", text: "Tap UNDO or press Spacebar to undo")
                    hintRow(icon: "gearshape.fill", text: "Tap the gear icon for settings")
                    hintRow(icon: "arrow.left.arrow.right", text: "Tap SWAP to switch court sides")
                }

                Button(action: onDismiss) {
                    Text("GOT IT")
                        .font(.system(size: layout.matchOverButtonFont, weight: .bold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 14)
                        .background(GoldColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding(.top, 8)
            }
        }
        .transition(.opacity)
    }

    private func hintRow(icon: String, text: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: layout.matchOverButtonIcon))
                .foregroundColor(GoldColor)
                .frame(width: 36, alignment: .center)

            Text(text)
                .font(.system(size: layout.matchOverButtonFont))
                .foregroundColor(.white)
        }
    }
}
