import SwiftUI

struct MatchHistoryView: View {
    let vm: MatchViewModel
    let onBack: () -> Void

    var body: some View {
        let matches = vm.matchHistory

        ZStack {
            DarkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 8) {
                        Button(action: onBack) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        Spacer().frame(width: 8)
                        Text("MATCH HISTORY")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    if !matches.isEmpty {
                        Button(action: { vm.deleteAllHistory() }) {
                            Image(systemName: "trash.slash.fill")
                                .font(.system(size: 28))
                                .foregroundColor(Color(red: 1, green: 0.33, blue: 0.33))
                        }
                    }
                }
                .padding(16)
                .background(ButtonBg)

                if matches.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 64))
                            .foregroundColor(DimColor)
                        Text("No matches yet")
                            .font(.system(size: 20))
                            .foregroundColor(DimColor)
                        Text("Completed matches will appear here")
                            .font(.system(size: 14))
                            .foregroundColor(DimColor.opacity(0.6))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(matches) { match in
                                MatchCardView(match: match, onDelete: { vm.deleteMatch(id: match.id) })
                            }
                        }
                        .padding(16)
                    }
                }
            }
        }
    }
}

struct MatchCardView: View {
    let match: SavedMatch
    let onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date and actions
            HStack {
                Text(match.formattedDate)
                    .font(.system(size: 13))
                    .foregroundColor(DimColor)
                Spacer()

                ShareLink(item: match.shareText()) {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 22))
                        .foregroundColor(.white)
                }

                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 22))
                        .foregroundColor(Color(red: 1, green: 0.33, blue: 0.33))
                }
            }

            Spacer().frame(height: 8)

            // Team names and set score
            HStack {
                Text(match.team1Name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Team1Blue)
                Spacer()
                Text("\(match.team1Sets) - \(match.team2Sets)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(match.team2Name)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Team2Red)
            }

            Spacer().frame(height: 8)

            // Game scores per set
            HStack(spacing: 0) {
                Spacer()
                ForEach(0..<match.team1Games.count, id: \.self) { i in
                    if i > 0 {
                        Text("  ")
                            .font(.system(size: 16))
                            .foregroundColor(DimColor)
                    }
                    let g2 = i < match.team2Games.count ? match.team2Games[i] : 0
                    Text("\(match.team1Games[i])-\(g2)")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(DimColor)
                }
                Spacer()
            }

            Spacer().frame(height: 12)
            Divider().background(Color(white: 0.2))
            Spacer().frame(height: 12)

            // Stats row
            HStack {
                Spacer()
                statItem(
                    icon: "trophy.fill",
                    label: "Winner",
                    value: match.winnerName,
                    valueColor: match.winner == 1 ? Team1Blue : Team2Red
                )
                Spacer()
                statItem(
                    icon: "timer",
                    label: "Duration",
                    value: match.formattedDuration,
                    valueColor: .white
                )
                Spacer()

                let totalPoints = match.team1PointsWon + match.team2PointsWon
                if totalPoints > 0 {
                    let t1Pct = (match.team1PointsWon * 100) / totalPoints
                    statItem(
                        icon: nil,
                        label: "Points Won",
                        value: "\(t1Pct)% - \(100 - t1Pct)%",
                        valueColor: GoldColor
                    )
                    Spacer()
                }
            }
        }
        .padding(20)
        .background(ButtonBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func statItem(icon: String?, label: String, value: String, valueColor: Color) -> some View {
        VStack(spacing: 2) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(DimColor)
                Spacer().frame(height: 4)
            }
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(DimColor)
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(valueColor)
        }
    }
}
