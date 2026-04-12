import SwiftUI

struct ScoreBoardView: View {
    let vm: MatchViewModel
    var onShowHistory: () -> Void = {}

    @Environment(\.layout) private var layout
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var showNewMatchConfirmation = false
    @AppStorage("has_seen_onboarding") private var hasSeenOnboarding = false
    @AppStorage("camera_overlay_enabled") private var cameraEnabled = false

    var body: some View {
        let state = vm.state
        let (display1, display2) = PadelScoring.displayPoints(state: state, goldenPoint: vm.goldenPoint)

        let team1Bg = vm.team1Color
        let team1Accent = vm.team1Color.contrastingTextColor
        let team2Bg = vm.team2Color
        let team2Accent = vm.team2Color.contrastingTextColor

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
                    .fill(
                        LinearGradient(
                            colors: [.clear, Color(white: 0.15), Color(white: 0.2), Color(white: 0.15), .clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
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

            // Top-left buttons (icon-only)
            VStack {
                HStack(spacing: layout.toolbarSpacing) {
                    scoreBoardButton(
                        icon: "arrow.uturn.backward",
                        disabled: !vm.canUndo
                    ) { vm.undo() }
                    .accessibilityLabel("UNDO")

                    scoreBoardButton(
                        icon: "arrow.left.arrow.right"
                    ) { HapticService.settingChanged(); vm.swapSides() }
                    .accessibilityLabel("SWAP")

                    if cameraEnabled {
                        Button(action: { showCamera.toggle() }) {
                            Image(systemName: "video.fill")
                                .font(.system(size: layout.toolbarIconSize))
                        }
                        .buttonStyle(ScoreBoardButtonStyle(
                            bgColor: showCamera ? Color(red: 0x8B / 255.0, green: 0, blue: 0) : ButtonBg
                        ))
                        .accessibilityLabel(showCamera ? "Hide camera" : "Show camera")
                    }

                    scoreBoardButton(
                        icon: "arrow.clockwise"
                    ) {
                        HapticService.buttonPress()
                        if vm.matchRunning || state.team1Points > 0 || state.team2Points > 0 {
                            showNewMatchConfirmation = true
                        } else {
                            vm.resetMatch()
                        }
                    }
                    .accessibilityLabel("NEW MATCH")

                    Spacer()
                }
                .padding(layout.panelPadding)
                Spacer()
            }

            // Top-right: Settings, Timer + completed set scores
            VStack {
                HStack {
                    Spacer()
                    VStack(alignment: .trailing, spacing: 8) {
                        HStack(spacing: layout.toolbarSpacing) {
                            MatchTimerView(vm: vm)

                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: layout.toolbarIconSize))
                            }
                            .buttonStyle(ScoreBoardButtonStyle())
                            .accessibilityLabel("Settings")
                        }

                        ForEach(0..<leftGamesList.count, id: \.self) { index in
                            if index < state.currentSet || (state.isMatchOver && index <= state.currentSet) {
                                compactSetPill(
                                    setIndex: index,
                                    leftGames: leftGamesList[index],
                                    rightGames: rightGamesList[index]
                                )
                                .transition(.scale.combined(with: .opacity))
                            }
                        }

                        if state.isTiebreak {
                            Text("TB")
                                .font(.system(size: layout.compactTiebreakFont, weight: .bold))
                                .foregroundColor(GoldColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(GoldColor.opacity(0.15))
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: state.currentSet)
                    .animation(.easeInOut(duration: 0.3), value: state.isTiebreak)
                }
                .padding(layout.panelPadding)
                Spacer()
            }

            // Serve side indicator — bottom center
            if vm.showServeSide {
                VStack {
                    Spacer()
                    ServeSideIndicatorView(
                        totalPoints: state.team1Points + state.team2Points,
                        isMatchOver: state.isMatchOver
                    )
                    .padding(.bottom, layout.panelPadding)
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
                onClose: { showSettings = false },
                onShowHistory: onShowHistory
            )

            // Onboarding overlay (first launch only)
            if !hasSeenOnboarding {
                OnboardingOverlayView(onDismiss: {
                    withAnimation { hasSeenOnboarding = true }
                })
            }
        }
        .confirmationDialog("Start New Match?", isPresented: $showNewMatchConfirmation) {
            Button("New Match", role: .destructive) { vm.resetMatch() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Current match progress will be lost.")
        }
        .onChange(of: cameraEnabled) { _, newValue in
            if !newValue { showCamera = false }
        }
    }

    private func scoreBoardButton(
        icon: String,
        disabled: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: layout.toolbarIconSize))
        }
        .buttonStyle(ScoreBoardButtonStyle())
        .disabled(disabled)
        .opacity(disabled ? 0.3 : 1.0)
    }

    private func compactSetPill(setIndex: Int, leftGames: Int, rightGames: Int) -> some View {
        VStack(spacing: 2) {
            Text("S\(setIndex + 1)")
                .font(.system(size: layout.compactSetLabelFont, weight: .bold))
                .foregroundColor(DimColor)
            HStack(spacing: 3) {
                Text("\(leftGames)")
                Text(":")
                    .foregroundColor(DimColor)
                Text("\(rightGames)")
            }
            .font(.system(size: layout.compactSetScoreFont, weight: .bold))
            .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct ScoreBoardButtonStyle: ButtonStyle {
    var bgColor: Color = ButtonBg
    var size: CGFloat = 44

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
            configuration.label
                .foregroundColor(.white)
        }
        .frame(width: size, height: size)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
