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
    var gamesBoxAtStart: Bool = false
    let onClick: () -> Void

    @State private var scoreScale: CGFloat = 1.0
    @State private var scoreVersion = 0

    var body: some View {
        let currentGames = currentSet < gamesList.count ? gamesList[currentSet] : 0

        ZStack {
            backgroundColor
                .contentShape(Rectangle())
                .onTapGesture { onClick() }

            // Games box — top corner near center
            VStack(spacing: 0) {
                HStack {
                    if gamesBoxAtStart {
                        gamesBox(currentGames: currentGames)
                        Spacer()
                    } else {
                        Spacer()
                        gamesBox(currentGames: currentGames)
                    }
                }
                .padding(.top, 16)
                .padding(.horizontal, 16)
                Spacer()
            }

            // Giant score — centered
            VStack {
                Spacer()
                    .frame(height: 40)
                Text(pointDisplay)
                    .font(.system(size: 400, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.3)
                    .lineLimit(1)
                    .scaleEffect(scoreScale)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.55), value: pointDisplay)
                Spacer()
            }
            .padding(.horizontal, 20)

            // Team name — top corner opposite to games box
            VStack {
                HStack {
                    if gamesBoxAtStart {
                        Spacer()
                        teamNameRow
                    } else {
                        teamNameRow
                        Spacer()
                    }
                }
                .padding(.top, 125)
                .padding(.horizontal, 86)
                Spacer()
            }
        }
        .onChange(of: pointDisplay) { _, _ in
            scoreVersion += 1
            if scoreVersion > 1 {
                scoreScale = 1.08
                withAnimation(.spring(response: 0.4, dampingFraction: 0.55)) {
                    scoreScale = 1.0
                }
            }
        }
    }

    private var teamNameRow: some View {
        HStack(spacing: 8) {
            if isServing {
                Image(systemName: "tennisball.fill")
                    .foregroundColor(GoldColor)
                    .font(.system(size: 28))
            }
            Text(teamLabel)
                .font(.system(size: 56, weight: .bold))
                .foregroundColor(accentColor)
                .tracking(3)
        }
    }

    private func gamesBox(currentGames: Int) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.3))
                .frame(width: 160, height: 200)

            VStack {
                Text("GAMES")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(backgroundColor)
                    .tracking(3)
                    .padding(.top, 12)

                Spacer()

                Text("\(currentGames)")
                    .font(.system(size: 160, weight: .bold))
                    .foregroundColor(.white)
                    .minimumScaleFactor(0.5)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: currentGames)

                Spacer()
            }
            .frame(width: 160, height: 200)
        }
    }
}
