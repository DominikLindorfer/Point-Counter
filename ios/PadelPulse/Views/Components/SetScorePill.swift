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
        VStack(spacing: 0) {
            Text("SET \(setIndex + 1)")
                .font(.system(size: labelFontSize, weight: .medium))
                .foregroundColor(DimColor)
                .tracking(1)

            HStack(spacing: 4) {
                Text("\(leftGames)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(leftColor)
                Text(":")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(DimColor)
                Text("\(rightGames)")
                    .font(.system(size: fontSize, weight: .bold))
                    .foregroundColor(rightColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
        .background(ButtonBg)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
