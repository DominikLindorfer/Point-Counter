import SwiftUI

struct MatchHistoryView: View {
    let vm: MatchViewModel
    let onBack: () -> Void

    @Environment(\.layout) private var layout
    @State private var showDeleteAllConfirmation = false

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
                                .font(.system(size: layout.historyHeaderIcon))
                                .foregroundColor(.white)
                        }
                        .accessibilityLabel("Back to scoreboard")
                        Spacer().frame(width: 8)
                        Text("MATCH HISTORY")
                            .font(.system(size: layout.historyHeaderFont, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    if !matches.isEmpty {
                        Button(action: { showDeleteAllConfirmation = true }) {
                            HStack(spacing: 6) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: layout.historyStatIcon))
                                Text("Delete All")
                                    .font(.system(size: layout.historyStatValue, weight: .semibold))
                            }
                            .foregroundColor(Color(red: 1, green: 0.45, blue: 0.45))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(Color(red: 1, green: 0.33, blue: 0.33).opacity(0.12))
                            .clipShape(Capsule())
                        }
                        .accessibilityLabel("Delete all match history")
                    }
                }
                .padding(layout.panelPadding)
                .background(ButtonBg)

                if matches.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: layout.historyEmptyIcon))
                            .foregroundColor(DimColor)
                        Text("No matches yet")
                            .font(.system(size: layout.historyEmptyTitle))
                            .foregroundColor(DimColor)
                        Text("Completed matches will appear here")
                            .font(.system(size: layout.historyEmptySubtitle))
                            .foregroundColor(DimColor.opacity(0.6))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(matches) { match in
                                MatchCardView(match: match, onDelete: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        vm.deleteMatch(id: match.id)
                                    }
                                })
                                .transition(.asymmetric(
                                    insertion: .opacity,
                                    removal: .slide.combined(with: .opacity)
                                ))
                            }
                        }
                        .padding(layout.panelPadding)
                    }
                }
            }
        }
        .confirmationDialog("Delete All History?", isPresented: $showDeleteAllConfirmation) {
            Button("Delete All", role: .destructive) { vm.deleteAllHistory() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This cannot be undone.")
        }
    }
}

struct MatchCardView: View {
    let match: SavedMatch
    let onDelete: () -> Void

    @Environment(\.layout) private var layout

    var body: some View {
        let totalPoints = match.team1PointsWon + match.team2PointsWon
        let t1Pct = totalPoints > 0 ? (match.team1PointsWon * 100) / totalPoints : 50
        let numSets = max(match.team1Games.count, match.team2Games.count)
        let setColWidth = layout.historyCardGameScore * 1.6
        let setsColWidth = layout.historyCardScore * 1.1

        VStack(alignment: .leading, spacing: 0) {
            // Header: date + delete
            HStack(spacing: 12) {
                Text(match.formattedDate)
                    .font(.system(size: layout.historyCardDate))
                    .foregroundColor(DimColor)
                Spacer()
                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: layout.historyCardAction))
                        .foregroundColor(Color(red: 1, green: 0.33, blue: 0.33))
                }
                .accessibilityLabel("Delete this match")
            }

            Spacer().frame(height: 18)

            // Team rows — ATP/WTA score-card style
            VStack(spacing: 10) {
                teamRow(
                    name: match.team1Name,
                    color: Team1Blue,
                    games: match.team1Games,
                    sets: match.team1Sets,
                    isWinner: match.winner == 1,
                    numSets: numSets,
                    setColWidth: setColWidth,
                    setsColWidth: setsColWidth
                )
                teamRow(
                    name: match.team2Name,
                    color: Team2Red,
                    games: match.team2Games,
                    sets: match.team2Sets,
                    isWinner: match.winner == 2,
                    numSets: numSets,
                    setColWidth: setColWidth,
                    setsColWidth: setsColWidth
                )
            }

            Spacer().frame(height: 16)
            Divider().background(Color(white: 0.18))
            Spacer().frame(height: 12)

            // Stats row — icon + value pairs, left-aligned
            HStack(spacing: 24) {
                statChip(
                    icon: "timer",
                    value: match.formattedDuration,
                    valueColor: .white
                )
                if totalPoints > 0 {
                    statChip(
                        icon: "chart.bar.fill",
                        value: "\(t1Pct)% · \(100 - t1Pct)%",
                        valueColor: GoldColor
                    )
                }
                Spacer()
            }
        }
        .padding(20)
        .background(ButtonBg)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private func teamRow(
        name: String,
        color: Color,
        games: [Int],
        sets: Int,
        isWinner: Bool,
        numSets: Int,
        setColWidth: CGFloat,
        setsColWidth: CGFloat
    ) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "trophy.fill")
                .font(.system(size: layout.historyStatIcon))
                .foregroundColor(GoldColor)
                .opacity(isWinner ? 1 : 0)
                .frame(width: layout.historyStatIcon)

            Text(name)
                .font(.system(size: layout.historyCardTeamName, weight: isWinner ? .bold : .semibold))
                .foregroundColor(isWinner ? color : color.opacity(0.55))
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 6) {
                ForEach(0..<numSets, id: \.self) { i in
                    Text(i < games.count ? "\(games[i])" : "–")
                        .font(.system(size: layout.historyCardGameScore, weight: isWinner ? .bold : .medium))
                        .foregroundColor(isWinner ? .white : DimColor)
                        .monospacedDigit()
                        .frame(width: setColWidth, alignment: .center)
                }
            }

            Text("\(sets)")
                .font(.system(size: layout.historyCardScore, weight: .bold))
                .foregroundColor(isWinner ? .white : DimColor.opacity(0.8))
                .monospacedDigit()
                .frame(width: setsColWidth, alignment: .trailing)
        }
    }

    private func statChip(icon: String, value: String, valueColor: Color) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: layout.historyStatIcon))
                .foregroundColor(DimColor)
            Text(value)
                .font(.system(size: layout.historyStatValue, weight: .semibold))
                .foregroundColor(valueColor)
                .monospacedDigit()
        }
    }
}

/// UIKit bridge for sharing a UIImage via the system share sheet.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
