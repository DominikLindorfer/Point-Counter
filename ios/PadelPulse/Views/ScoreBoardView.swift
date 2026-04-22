import SwiftUI

struct ScoreBoardView: View {
    let vm: MatchViewModel
    var onShowHistory: () -> Void = {}
    var onShowCredits: () -> Void = {}

    @Environment(\.layout) private var layout
    @State private var showSettings = false
    @State private var showCamera = false
    @State private var showNewMatchConfirmation = false
    @AppStorage(DefaultsKey.hasSeenOnboarding) private var hasSeenOnboarding = false
    @AppStorage(DefaultsKey.cameraOverlayEnabled) private var cameraEnabled = false

    /// Snapshot of one side of the scoreboard (left or right), already resolved
    /// against `sidesSwapped` so the view layer doesn't repeat the ternary dance.
    private struct SideSnapshot {
        let name: String
        let display: String
        let bg: Color
        let accent: Color
        let sets: Int
        let gamesList: [Int]
        let team: Int
    }

    private func snapshot(
        isLeft: Bool,
        display1: String,
        display2: String,
        team1Accent: Color,
        team2Accent: Color
    ) -> SideSnapshot {
        let state = vm.state
        let team1OnThisSide = isLeft != vm.sidesSwapped
        return SideSnapshot(
            name: team1OnThisSide ? vm.team1Name : vm.team2Name,
            display: team1OnThisSide ? display1 : display2,
            bg: team1OnThisSide ? vm.team1Color : vm.team2Color,
            accent: team1OnThisSide ? team1Accent : team2Accent,
            sets: team1OnThisSide ? state.team1Sets : state.team2Sets,
            gamesList: team1OnThisSide ? state.team1Games : state.team2Games,
            team: team1OnThisSide ? 1 : 2
        )
    }

    var body: some View {
        let state = vm.state
        let (display1, display2) = PadelScoring.displayPoints(state: state, goldenPoint: vm.goldenPoint)

        let team1Accent = vm.team1Color.contrastingTextColor
        let team2Accent = vm.team2Color.contrastingTextColor

        let left = snapshot(isLeft: true, display1: display1, display2: display2,
                            team1Accent: team1Accent, team2Accent: team2Accent)
        let right = snapshot(isLeft: false, display1: display1, display2: display2,
                             team1Accent: team1Accent, team2Accent: team2Accent)

        let servingOnLeft = (vm.servingTeam == 1 && !vm.sidesSwapped) ||
            (vm.servingTeam == 2 && vm.sidesSwapped)

        ZStack {
            DarkBg.ignoresSafeArea()

            // Main content: two halves
            HStack(spacing: 0) {
                let serveOnLeft = (state.team1Points + state.team2Points) % 2 != 0

                TeamPanelView(
                    teamLabel: left.name,
                    pointDisplay: left.display,
                    backgroundColor: left.bg,
                    accentColor: left.accent,
                    isServing: servingOnLeft,
                    setsWon: left.sets,
                    gamesList: left.gamesList,
                    opponentGamesList: right.gamesList,
                    currentSet: state.currentSet,
                    isMatchOver: state.isMatchOver,
                    isTiebreak: state.isTiebreak,
                    showServeSide: vm.showServeSide,
                    serveOnLeft: serveOnLeft,
                    onClick: { vm.scorePoint(team: left.team) }
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
                    teamLabel: right.name,
                    pointDisplay: right.display,
                    backgroundColor: right.bg,
                    accentColor: right.accent,
                    isServing: !servingOnLeft,
                    setsWon: right.sets,
                    gamesList: right.gamesList,
                    opponentGamesList: left.gamesList,
                    currentSet: state.currentSet,
                    isMatchOver: state.isMatchOver,
                    isTiebreak: state.isTiebreak,
                    showServeSide: vm.showServeSide,
                    serveOnLeft: serveOnLeft,
                    gamesBoxAtStart: true,
                    onClick: { vm.scorePoint(team: right.team) }
                )
            }
            .ignoresSafeArea()

            // Top-left buttons (icon-only)
            VStack {
                HStack(spacing: layout.toolbarSpacing) {
                    scoreBoardButton(
                        icon: "arrow.uturn.backward",
                        disabled: !vm.canUndo
                    ) { vm.undo() }
                    .accessibilityLabel("Undo")

                    scoreBoardButton(
                        icon: "arrow.left.arrow.right"
                    ) { HapticService.settingChanged(); vm.swapSides() }
                    .accessibilityLabel("Swap sides")

                    if cameraEnabled {
                        scoreBoardButton(
                            icon: "video.fill",
                            bgColor: showCamera ? Color(red: 0x8B / 255.0, green: 0, blue: 0) : ButtonBg
                        ) { showCamera.toggle() }
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
                    .accessibilityLabel("New match")

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
                            WallClockView()

                            MatchTimerView(vm: vm)

                            Button(action: { showSettings = true }) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: layout.toolbarIconSize))
                            }
                            .buttonStyle(ScoreBoardButtonStyle())
                            .accessibilityLabel("Settings")
                        }

                        HStack(spacing: 6) {
                            ForEach(0..<left.gamesList.count, id: \.self) { index in
                                if index < state.currentSet || (state.isMatchOver && index <= state.currentSet) {
                                    compactSetPill(
                                        setIndex: index,
                                        leftGames: left.gamesList[index],
                                        rightGames: right.gamesList[index]
                                    )
                                    .transition(.scale.combined(with: .opacity))
                                }
                            }

                            if state.isTiebreak {
                                Text(LocalizedStringKey("TB"))
                                    .font(.system(size: layout.compactTiebreakFont, weight: .bold))
                                    .foregroundColor(GoldColor)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(GoldColor.opacity(0.15))
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                    .transition(.scale.combined(with: .opacity))
                            }
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: state.currentSet)
                    .animation(.easeInOut(duration: 0.3), value: state.isTiebreak)
                }
                .padding(layout.panelPadding)
                Spacer()
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
                    leftGamesList: left.gamesList,
                    rightGamesList: right.gamesList,
                    leftBg: left.bg,
                    rightBg: right.bg,
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
                onShowHistory: onShowHistory,
                onShowCredits: onShowCredits
            )

            // Onboarding overlay (first launch only)
            if !hasSeenOnboarding {
                OnboardingOverlayView(onDismiss: {
                    withAnimation { hasSeenOnboarding = true }
                })
            }
        }
        // .alert instead of .confirmationDialog: on iPad the confirmation
        // dialog renders as a popover that hides the Cancel role behind
        // "tap outside to dismiss" — users couldn't see an explicit abort.
        .alert("Start New Match?", isPresented: $showNewMatchConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("New Match", role: .destructive) { vm.resetMatch() }
        } message: {
            Text("Current match progress will be lost.")
        }
        .onChange(of: cameraEnabled) { _, newValue in
            if !newValue { showCamera = false }
        }
        .onReceive(NotificationCenter.default.publisher(for: .toggleSettings)) { _ in
            showSettings.toggle()
        }
    }

    private func scoreBoardButton(
        icon: String,
        disabled: Bool = false,
        bgColor: Color = ButtonBg,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: layout.toolbarIconSize))
        }
        .buttonStyle(ScoreBoardButtonStyle(bgColor: bgColor))
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

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(bgColor)
            configuration.label
                .foregroundColor(.white)
        }
        .frame(width: 44, height: 44)
        .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
        .opacity(configuration.isPressed ? 0.8 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
