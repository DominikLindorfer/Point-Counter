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
                            Image(systemName: "trash.slash.fill")
                                .font(.system(size: layout.historyHeaderIcon))
                                .foregroundColor(Color(red: 1, green: 0.33, blue: 0.33))
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
    @State private var shareImage: UIImage?
    @State private var showShareSheet = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Date and actions
            HStack {
                Text(match.formattedDate)
                    .font(.system(size: layout.historyCardDate))
                    .foregroundColor(DimColor)
                Spacer()

                Menu {
                    ShareLink(item: match.shareText()) {
                        Label("Share as Text", systemImage: "text.alignleft")
                    }
                    Button {
                        if let image = ShareImageRenderer.render(match: match) {
                            shareImage = image
                            showShareSheet = true
                        }
                    } label: {
                        Label("Share as Image", systemImage: "photo")
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: layout.historyCardAction))
                        .foregroundColor(.white)
                }
                .accessibilityLabel("Share match result")

                Button(action: onDelete) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: layout.historyCardAction))
                        .foregroundColor(Color(red: 1, green: 0.33, blue: 0.33))
                }
                .accessibilityLabel("Delete this match")
            }

            Spacer().frame(height: 8)

            // Team names and set score
            HStack {
                Text(match.team1Name)
                    .font(.system(size: layout.historyCardTeamName, weight: .bold))
                    .foregroundColor(Team1Blue)
                Spacer()
                Text("\(match.team1Sets) - \(match.team2Sets)")
                    .font(.system(size: layout.historyCardScore, weight: .bold))
                    .foregroundColor(.white)
                Spacer()
                Text(match.team2Name)
                    .font(.system(size: layout.historyCardTeamName, weight: .bold))
                    .foregroundColor(Team2Red)
            }

            Spacer().frame(height: 8)

            // Game scores per set
            HStack(spacing: 12) {
                Spacer()
                ForEach(0..<match.team1Games.count, id: \.self) { i in
                    let g2 = i < match.team2Games.count ? match.team2Games[i] : 0
                    Text("\(match.team1Games[i])-\(g2)")
                        .font(.system(size: layout.historyCardGameScore, weight: .medium))
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
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
    }

    private func statItem(icon: String?, label: LocalizedStringKey, value: String, valueColor: Color) -> some View {
        VStack(spacing: 2) {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: layout.historyStatIcon))
                    .foregroundColor(DimColor)
                Spacer().frame(height: 4)
            }
            Text(label)
                .font(.system(size: layout.historyStatLabel))
                .foregroundColor(DimColor)
            Text(value)
                .font(.system(size: layout.historyStatValue, weight: .bold))
                .foregroundColor(valueColor)
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
