import SwiftUI

struct SetScorePill: View {
    let setIndex: Int
    let leftGames: Int
    let rightGames: Int
    let leftColor: Color
    let rightColor: Color
    var fontSize: CGFloat = 40
    var labelFontSize: CGFloat = 16

    var body: some View {
        let leftWins = leftGames > rightGames
        let rightWins = rightGames > leftGames

        VStack(spacing: 2) {
            Text("SET \(setIndex + 1)")
                .font(.system(size: labelFontSize, weight: .medium))
                .foregroundColor(DimColor)
                .tracking(1)

            HStack(spacing: 4) {
                Text("\(leftGames)")
                    .font(.system(size: fontSize, weight: leftWins ? .bold : .medium))
                    .foregroundColor(leftWins ? .white : .white.opacity(0.45))
                    .monospacedDigit()
                Text(":")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(DimColor.opacity(0.6))
                Text("\(rightGames)")
                    .font(.system(size: fontSize, weight: rightWins ? .bold : .medium))
                    .foregroundColor(rightWins ? .white : .white.opacity(0.45))
                    .monospacedDigit()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
        .background(ButtonBg)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
