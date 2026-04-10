import SwiftUI

struct MatchOverOverlayView: View {
    let vm: MatchViewModel
    let leftGamesList: [Int]
    let rightGamesList: [Int]
    let leftBg: Color
    let rightBg: Color
    let team1Accent: Color
    let team2Accent: Color

    @State private var trophyScale: CGFloat = 0

    var body: some View {
        let state = vm.state
        let winnerName = state.winner == 1 ? vm.team1Name : vm.team2Name
        let winnerColor = state.winner == 1 ? team1Accent : team2Accent

        ZStack {
            Color.black.opacity(0.87)
                .ignoresSafeArea()
                .contentShape(Rectangle())

            VStack(spacing: 0) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 80))
                    .foregroundColor(GoldColor)
                    .scaleEffect(trophyScale)

                Spacer().frame(height: 16)

                Text("MATCH OVER")
                    .font(.system(size: 52, weight: .bold))
                    .foregroundColor(.white)

                Spacer().frame(height: 12)

                Text("\(winnerName) wins!")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(winnerColor)

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
                                fontSize: 36,
                                labelFontSize: 14
                            )
                        }
                    }
                }

                Spacer().frame(height: 32)

                Button(action: { vm.resetMatch() }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 24))
                        Text("NEW MATCH")
                            .font(.system(size: 20, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(winnerColor)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                trophyScale = 1.0
            }
        }
    }
}
