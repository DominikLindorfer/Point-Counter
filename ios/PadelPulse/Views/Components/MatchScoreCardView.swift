import SwiftUI

/// A score card view designed for rendering to an image for sharing.
struct MatchScoreCardView: View {
    let match: SavedMatch

    var body: some View {
        let winnerIsTeam1 = match.winner == 1

        VStack(spacing: 0) {
            // Branding
            Text("PADEL PULSE")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(GoldColor)
                .tracking(4)
                .padding(.top, 20)

            Text(match.formattedDate)
                .font(.system(size: 11))
                .foregroundColor(DimColor)
                .padding(.top, 4)

            Spacer().frame(height: 20)

            // Team names + set score
            HStack {
                VStack(spacing: 4) {
                    Text(match.team1Name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(winnerIsTeam1 ? GoldColor : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if winnerIsTeam1 {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                            .foregroundColor(GoldColor)
                    }
                }
                .frame(maxWidth: .infinity)

                Text("\(match.team1Sets) - \(match.team2Sets)")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)

                VStack(spacing: 4) {
                    Text(match.team2Name)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(!winnerIsTeam1 ? GoldColor : .white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                    if !winnerIsTeam1 {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 14))
                            .foregroundColor(GoldColor)
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)

            Spacer().frame(height: 16)

            // Game scores per set
            HStack(spacing: 16) {
                ForEach(0..<match.team1Games.count, id: \.self) { i in
                    let g2 = i < match.team2Games.count ? match.team2Games[i] : 0
                    VStack(spacing: 2) {
                        Text("SET \(i + 1)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(DimColor)
                        Text("\(match.team1Games[i]) - \(g2)")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }

            Spacer().frame(height: 16)

            // Stats row
            HStack(spacing: 24) {
                statItem(label: "DURATION", value: match.formattedDuration)
                if match.team1PointsWon + match.team2PointsWon > 0 {
                    statItem(label: "POINTS", value: "\(match.team1PointsWon) - \(match.team2PointsWon)")
                }
                if match.goldenPoint {
                    statItem(label: "MODE", value: "GOLDEN PT")
                }
            }
            .padding(.bottom, 20)
        }
        .frame(width: 600, height: 315)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 0x12 / 255.0, green: 0x12 / 255.0, blue: 0x12 / 255.0))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(GoldColor.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func statItem(label: LocalizedStringKey, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(DimColor)
            Text(value)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}
