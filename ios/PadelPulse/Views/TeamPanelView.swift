import SwiftUI

struct TeamPanelView: View {
    let teamLabel: String
    let pointDisplay: String
    let backgroundColor: Color
    let accentColor: Color
    let isServing: Bool
    let setsWon: Int
    let gamesList: [Int]
    let opponentGamesList: [Int]
    let currentSet: Int
    let isMatchOver: Bool
    let isTiebreak: Bool
    let showServeSide: Bool
    let serveOnLeft: Bool
    var gamesBoxAtStart: Bool = false
    let onClick: () -> Void

    @Environment(\.layout) private var layout
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowPulse: CGFloat = 0.35

    private var serveIndicatorVisible: Bool {
        isServing && showServeSide && !isMatchOver
    }

    var body: some View {
        let currentGames = currentSet < gamesList.count ? gamesList[currentSet] : 0

        ZStack {
            LinearGradient(
                colors: [backgroundColor, backgroundColor.opacity(0.85)],
                startPoint: .top,
                endPoint: .bottom
            )
            .contentShape(Rectangle())
            .onTapGesture { onClick() }

            VStack(spacing: 0) {
                // Games box — top corner near center
                HStack {
                    if gamesBoxAtStart {
                        gamesBox(currentGames: currentGames)
                            .padding(.leading, layout.panelPadding)
                        Spacer()
                    } else {
                        Spacer()
                        gamesBox(currentGames: currentGames)
                            .padding(.trailing, layout.panelPadding)
                    }
                }
                .padding(.top, layout.gamesBoxTopPadding)
                .padding(.bottom, layout.gamesBoxTopPadding)
                .padding(.horizontal, layout.panelPadding)

                Spacer()

                // Team name above score
                teamNameRow

                // Giant score
                Text(pointDisplay)
                    .font(.system(size: layout.scoreFont, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.55), value: pointDisplay)
                    .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.bottom, layout.serveAreaClearance)

            if serveIndicatorVisible {
                serveOverlay
            }
        }
        .overlay(
            // Pulsing gold border on the serving panel — second redundant cue
            // so which side is serving is obvious without squinting at the
            // racket icon. Only the outer corners (away from the center
            // divider) are rounded so the border stays visually anchored to
            // the panel structure instead of floating over it.
            UnevenRoundedRectangle(
                topLeadingRadius: gamesBoxAtStart ? 0 : 20,
                bottomLeadingRadius: gamesBoxAtStart ? 0 : 20,
                bottomTrailingRadius: gamesBoxAtStart ? 20 : 0,
                topTrailingRadius: gamesBoxAtStart ? 20 : 0
            )
            .strokeBorder(GoldColor, lineWidth: layout.servePanelGlowWidth)
            .opacity(serveIndicatorVisible ? glowPulse : 0)
            .allowsHitTesting(false)
        )
        .onAppear {
            if reduceMotion {
                glowPulse = 0.85
            } else {
                // Wider range (0.35 → 1.0) so the pulse actually reads on a
                // bright iPad screen in daylight. No scoped .animation modifier
                // on the overlay — it was competing with the repeatForever
                // animation and suppressing the pulse.
                withAnimation(.easeInOut(duration: 1.1).repeatForever(autoreverses: true)) {
                    glowPulse = 1.0
                }
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(teamLabel), score \(pointDisplay), \(currentGames) games")
        .accessibilityValue(isServing ? "Currently serving" : "")
        .accessibilityHint("Double tap to score a point for \(teamLabel)")
        .accessibilityAddTraits(.isButton)
    }

    /// Bottom-of-panel indicator: L or R letter paired with the racket icon
    /// in the corner corresponding to the deuce/ad side the server stands on.
    /// - serveOnLeft=true  → `[L][🏸]` flushed to the left corner
    /// - serveOnLeft=false → `[🏸][R]` flushed to the right corner
    /// The big letter is readable from across the court; the racket stays as
    /// a visual anchor for players who already recognized it.
    private var serveOverlay: some View {
        VStack {
            Spacer()
            HStack {
                if serveOnLeft {
                    HStack(spacing: 12) {
                        Text("L")
                            .font(.system(size: layout.serveLetterFont, weight: .black))
                            .foregroundColor(GoldColor)
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                        PadelRacketView(color: GoldColor, size: layout.servingRacketSize)
                    }
                    Spacer()
                } else {
                    Spacer()
                    HStack(spacing: 12) {
                        PadelRacketView(color: GoldColor, size: layout.servingRacketSize)
                        Text("R")
                            .font(.system(size: layout.serveLetterFont, weight: .black))
                            .foregroundColor(GoldColor)
                            .shadow(color: .black.opacity(0.4), radius: 4, y: 2)
                    }
                }
            }
            .padding(.horizontal, layout.panelPadding * 1.5)
            .padding(.bottom, layout.panelPadding * 1.5)
            .animation(.easeInOut(duration: 0.25), value: serveOnLeft)
        }
        .accessibilityHidden(true)
    }

    private var teamNameRow: some View {
        Text(teamLabel)
            .font(.system(size: layout.teamNameFont, weight: .bold))
            .foregroundColor(accentColor)
            .lineLimit(1)
            .minimumScaleFactor(0.5)
            .tracking(3)
            .padding(.horizontal, layout.panelPadding)
    }

    private func gamesBox(currentGames: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: layout.gamesBoxCorner)
                .fill(Color.black.opacity(0.3))
                .frame(width: layout.gamesBoxWidth, height: layout.gamesBoxHeight)

            Text("\(currentGames)")
                .font(.system(size: layout.gamesNumberFont, weight: .bold))
                .foregroundColor(.white)
                .minimumScaleFactor(0.5)
                .contentTransition(.numericText())
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentGames)
        }
    }
}
