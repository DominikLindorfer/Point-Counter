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

            if isServing && showServeSide && !isMatchOver {
                racketOverlay
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(teamLabel), score \(pointDisplay), \(currentGames) games")
        .accessibilityValue(isServing ? "Currently serving" : "")
        .accessibilityHint("Double tap to score a point for \(teamLabel)")
        .accessibilityAddTraits(.isButton)
    }

    private var racketOverlay: some View {
        VStack {
            Spacer()
            HStack {
                if serveOnLeft {
                    PadelRacketView(color: GoldColor, size: layout.servingRacketSize)
                    Spacer()
                } else {
                    Spacer()
                    PadelRacketView(color: GoldColor, size: layout.servingRacketSize)
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
