import SwiftUI

struct MatchOverOverlayView: View {
    let vm: MatchViewModel
    let leftGamesList: [Int]
    let rightGamesList: [Int]
    let leftBg: Color
    let rightBg: Color
    let team1Accent: Color
    let team2Accent: Color

    @Environment(\.layout) private var layout
    @State private var trophyScale: CGFloat = 0
    @State private var trophyOffset: CGFloat = -80
    @State private var showTitle = false
    @State private var showWinner = false
    @State private var showScores = false
    @State private var showButtons = false
    @State private var glowOpacity: CGFloat = 0.3
    @State private var showShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        let state = vm.state
        let winnerName = state.winner == 1 ? vm.team1Name : vm.team2Name
        let winnerColor = state.winner == 1 ? team1Accent : team2Accent
        let winnerBgColor = state.winner == 1 ? vm.team1Color : vm.team2Color

        ZStack {
            Color.black.opacity(0.87)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            // Confetti layer
            ConfettiView(colors: [GoldColor, winnerColor, .white, winnerColor.opacity(0.7)])
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: layout.trophySize))
                    .foregroundColor(GoldColor)
                    .scaleEffect(trophyScale)
                    .offset(y: trophyOffset)
                    .accessibilityHidden(true)

                Spacer().frame(height: 16)

                Text("MATCH OVER")
                    .font(.system(size: layout.matchOverTitleFont, weight: .bold))
                    .foregroundColor(.white)
                    .opacity(showTitle ? 1 : 0)
                    .offset(y: showTitle ? 0 : 15)

                Spacer().frame(height: 12)

                Text("\(winnerName) wins!")
                    .font(.system(size: layout.matchOverSubtitleFont, weight: .bold))
                    .foregroundColor(winnerColor)
                    .shadow(color: winnerColor.opacity(glowOpacity), radius: 20)
                    .opacity(showWinner ? 1 : 0)
                    .offset(y: showWinner ? 0 : 15)

                Spacer().frame(height: 24)

                // Set scores
                HStack(spacing: 16) {
                    ForEach(0..<leftGamesList.count, id: \.self) { index in
                        if index <= state.currentSet {
                            SetScorePill(
                                setIndex: index,
                                leftGames: leftGamesList[index],
                                rightGames: rightGamesList[index],
                                leftColor: leftBg,
                                rightColor: rightBg,
                                fontSize: layout.matchOverSubtitleFont,
                                labelFontSize: layout.historyStatValue
                            )
                        }
                    }
                }
                .opacity(showScores ? 1 : 0)
                .offset(y: showScores ? 0 : 15)

                Spacer().frame(height: 32)

                HStack(spacing: 16) {
                    Button {
                        let match = vm.currentMatchSnapshot()
                        if let image = ShareImageRenderer.render(match: match) {
                            shareImage = image
                            showShareSheet = true
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: layout.matchOverButtonIcon))
                            Text("SHARE")
                                .font(.system(size: layout.matchOverButtonFont, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.15))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Share match result")

                    Button(action: { vm.resetMatch() }) {
                        HStack(spacing: 8) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: layout.matchOverButtonIcon))
                            Text("NEW MATCH")
                                .font(.system(size: layout.matchOverButtonFont, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(winnerBgColor)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .accessibilityLabel("Start new match")
                }
                .opacity(showButtons ? 1 : 0)
                .offset(y: showButtons ? 0 : 15)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Match over. \(winnerName) wins")
        }
        .sheet(isPresented: $showShareSheet) {
            if let image = shareImage {
                ShareSheet(items: [image])
            }
        }
        .onAppear {
            // Trophy: fly in from above + spring scale
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                trophyScale = 1.0
                trophyOffset = 0
            }
            // Staggered entrance
            withAnimation(.easeOut(duration: 0.4).delay(0.3)) { showTitle = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.5)) { showWinner = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.7)) { showScores = true }
            withAnimation(.easeOut(duration: 0.4).delay(0.9)) { showButtons = true }
            // Winner name glow pulse
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true).delay(0.5)) {
                glowOpacity = 0.8
            }
        }
    }
}
