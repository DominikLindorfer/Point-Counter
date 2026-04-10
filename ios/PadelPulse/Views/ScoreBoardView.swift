import SwiftUI

struct ScoreBoardView: View {
    let vm: MatchViewModel
    var onShowHistory: () -> Void = {}

    @State private var showSettings = false
    @State private var showCamera = false

    var body: some View {
        let state = vm.state
        let (display1, display2) = PadelScoring.displayPoints(state: state, goldenPoint: vm.goldenPoint)

        let t1Color = teamColorPresets[vm.team1ColorIndex]
        let t2Color = teamColorPresets[vm.team2ColorIndex]
        let team1Bg = t1Color.bg
        let team1Accent = t1Color.accent
        let team2Bg = t2Color.bg
        let team2Accent = t2Color.accent

        // Determine which team shows on which side
        let leftName = vm.sidesSwapped ? vm.team2Name : vm.team1Name
        let rightName = vm.sidesSwapped ? vm.team1Name : vm.team2Name
        let leftDisplay = vm.sidesSwapped ? display2 : display1
        let rightDisplay = vm.sidesSwapped ? display1 : display2
        let leftBg = vm.sidesSwapped ? team2Bg : team1Bg
        let rightBg = vm.sidesSwapped ? team1Bg : team2Bg
        let leftAccent = vm.sidesSwapped ? team2Accent : team1Accent
        let rightAccent = vm.sidesSwapped ? team1Accent : team2Accent
        let leftTeam = vm.sidesSwapped ? 2 : 1
        let rightTeam = vm.sidesSwapped ? 1 : 2
        let leftSets = vm.sidesSwapped ? state.team2Sets : state.team1Sets
        let rightSets = vm.sidesSwapped ? state.team1Sets : state.team2Sets
        let leftGamesList = vm.sidesSwapped ? state.team2Games : state.team1Games
        let rightGamesList = vm.sidesSwapped ? state.team1Games : state.team2Games

        let servingOnLeft = (vm.servingTeam == 1 && !vm.sidesSwapped) ||
            (vm.servingTeam == 2 && vm.sidesSwapped)

        ZStack {
            DarkBg.ignoresSafeArea()

            // Main content: two halves
            HStack(spacing: 0) {
                TeamPanelView(
                    teamLabel: leftName,
                    pointDisplay: leftDisplay,
                    backgroundColor: leftBg,
                    accentColor: leftAccent,
                    isServing: servingOnLeft,
                    setsWon: leftSets,
                    gamesList: leftGamesList,
                    opponentGamesList: rightGamesList,
                    currentSet: state.currentSet,
                    isMatchOver: state.isMatchOver,
                    isTiebreak: state.isTiebreak,
                    onClick: { vm.scorePoint(team: leftTeam) }
                )

                Rectangle()
                    .fill(Color(red: 0x22 / 255.0, green: 0x22 / 255.0, blue: 0x22 / 255.0))
                    .frame(width: 2)

                TeamPanelView(
                    teamLabel: rightName,
                    pointDisplay: rightDisplay,
                    backgroundColor: rightBg,
                    accentColor: rightAccent,
                    isServing: !servingOnLeft,
                    setsWon: rightSets,
                    gamesList: rightGamesList,
                    opponentGamesList: leftGamesList,
                    currentSet: state.currentSet,
                    isMatchOver: state.isMatchOver,
                    isTiebreak: state.isTiebreak,
                    gamesBoxAtStart: true,
                    onClick: { vm.scorePoint(team: rightTeam) }
                )
            }

            // Top-left buttons
            VStack {
                HStack(spacing: 8) {
                    scoreBoardButton(
                        icon: "arrow.uturn.backward",
                        label: "UNDO",
                        disabled: !vm.canUndo
                    ) { vm.undo() }

                    scoreBoardButton(
                        icon: "arrow.left.arrow.right",
                        label: "SWAP"
                    ) { vm.swapSides() }

                    Button(action: { showCamera.toggle() }) {
                        Image(systemName: "video.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(ScoreBoardButtonStyle(
                        bgColor: showCamera ? Color(red: 0x8B / 255.0, green: 0, blue: 0) : ButtonBg
                    ))

                    Spacer()
                }
                .padding(16)
                Spacer()
            }

            // Top-right buttons
            VStack {
                HStack(spacing: 8) {
                    Spacer()

                    MatchTimerView(vm: vm)

                    scoreBoardButton(
                        icon: "arrow.clockwise",
                        label: "NEW MATCH"
                    ) { vm.resetMatch() }

                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(ScoreBoardButtonStyle())
                }
                .padding(16)
                Spacer()
            }

            // Completed set scores — bottom center
            VStack {
                Spacer()
                HStack(spacing: 16) {
                    ForEach(0..<leftGamesList.count, id: \.self) { index in
                        if index < state.currentSet || (state.isMatchOver && index <= state.currentSet) {
                            SetScorePill(
                                setIndex: index,
                                leftGames: leftGamesList[index],
                                rightGames: rightGamesList[index],
                                leftColor: leftBg,
                                rightColor: rightBg
                            )
                        }
                    }

                    if state.isTiebreak {
                        Text("TIEBREAK")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(GoldColor)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.easeInOut(duration: 0.3), value: state.isTiebreak)
                .padding(.bottom, 16)
            }

            // Serve side indicator — bottom center above set scores
            if vm.showServeSide {
                VStack {
                    Spacer()
                    ServeSideIndicatorView(
                        totalPoints: state.team1Points + state.team2Points,
                        isMatchOver: state.isMatchOver
                    )
                    .padding(.bottom, 110)
                }
            }

            // Camera overlay — bottom left
            if showCamera {
                VStack {
                    Spacer()
                    HStack {
                        CameraOverlayView(onClose: { showCamera = false })
                            .padding(.leading, 16)
                            .padding(.bottom, 80)
                        Spacer()
                    }
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.easeInOut(duration: 0.3), value: showCamera)
            }

            // Match over overlay
            if state.isMatchOver {
                MatchOverOverlayView(
                    vm: vm,
                    leftGamesList: leftGamesList,
                    rightGamesList: rightGamesList,
                    leftBg: leftBg,
                    rightBg: rightBg,
                    team1Accent: team1Accent,
                    team2Accent: team2Accent
                )
                .transition(.opacity)
                .animation(.easeInOut(duration: 0.5), value: state.isMatchOver)
            }

            // Settings sidebar
            SettingsSidebarView(
                visible: showSettings,
                vm: vm,
                team1Accent: team1Accent,
                team2Accent: team2Accent,
                onClose: { showSettings = false },
                onShowHistory: onShowHistory
            )
        }
    }

    private func scoreBoardButton(
        icon: String,
        label: String? = nil,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                if let label {
                    Text(label)
                        .font(.system(size: 14, weight: .bold))
                }
            }
        }
        .buttonStyle(ScoreBoardButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.3 : 1.0)
    }
}

struct ScoreBoardButtonStyle: ButtonStyle {
    var bgColor: Color = ButtonBg

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(bgColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .opacity(configuration.isPressed ? 0.7 : 1.0)
    }
}
