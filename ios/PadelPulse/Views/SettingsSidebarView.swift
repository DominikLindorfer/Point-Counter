import SwiftUI

struct SettingsSidebarView: View {
    let visible: Bool
    let vm: MatchViewModel
    let team1Accent: Color
    let team2Accent: Color
    let onClose: () -> Void
    var onShowHistory: () -> Void = {}

    @State private var team1NameBinding = ""
    @State private var team2NameBinding = ""

    var body: some View {
        if visible {
            // Dim overlay
            Color.black.opacity(0.5)
                .ignoresSafeArea()
                .onTapGesture { onClose() }
                .transition(.opacity)
        }

        HStack(spacing: 0) {
            Spacer()
            if visible {
                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        // Header
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "gearshape.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                                Text("SETTINGS")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: 28))
                                    .foregroundColor(.white)
                            }
                        }

                        Spacer().frame(height: 24)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 20)

                        // Team 1
                        sectionHeader("Team 1", color: team1Accent)
                        Spacer().frame(height: 12)
                        settingsLabel("Name")
                        NameFieldView(text: Binding(
                            get: { vm.team1Name },
                            set: { vm.updateTeam1Name($0) }
                        ))
                        Spacer().frame(height: 12)
                        settingsLabel("Color")
                        ColorPickerGrid(selectedIndex: vm.team1ColorIndex) { vm.updateTeam1Color($0) }

                        Spacer().frame(height: 24)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 20)

                        // Team 2
                        sectionHeader("Team 2", color: team2Accent)
                        Spacer().frame(height: 12)
                        settingsLabel("Name")
                        NameFieldView(text: Binding(
                            get: { vm.team2Name },
                            set: { vm.updateTeam2Name($0) }
                        ))
                        Spacer().frame(height: 12)
                        settingsLabel("Color")
                        ColorPickerGrid(selectedIndex: vm.team2ColorIndex) { vm.updateTeam2Color($0) }

                        Spacer().frame(height: 24)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 20)

                        // Match Rules
                        sectionHeader("Match Rules", color: GoldColor)
                        Spacer().frame(height: 16)

                        // Golden Point toggle
                        settingsRow(
                            icon: "sparkles",
                            iconColor: vm.goldenPoint ? GoldColor : DimColor,
                            label: "Scoring Mode",
                            value: vm.goldenPoint ? "GOLDEN PT" : "ADVANTAGE",
                            valueColor: vm.goldenPoint ? GoldColor : DimColor
                        ) { vm.toggleGoldenPoint() }

                        Spacer().frame(height: 8)

                        // Sets to win
                        settingsRow(
                            icon: "repeat",
                            iconColor: DimColor,
                            label: "Sets to Win",
                            value: vm.setsToWin == 0 ? "\u{221E}" : "\(vm.setsToWin)",
                            valueColor: .white
                        ) { vm.cycleSetsToWin() }

                        Spacer().frame(height: 8)

                        // First serve
                        let serveName = vm.servingTeam == 1 ? vm.team1Name : vm.team2Name
                        let serveColor = vm.servingTeam == 1 ? team1Accent : team2Accent
                        settingsRow(
                            icon: "tennisball.fill",
                            iconColor: DimColor,
                            label: "Serving",
                            value: serveName,
                            valueColor: serveColor
                        ) { vm.updateServingTeam(vm.servingTeam == 1 ? 2 : 1) }

                        Spacer().frame(height: 24)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 20)

                        // Match history button
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 24))
                                .foregroundColor(GoldColor)
                            Text("Match History")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(SettingsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture {
                            onClose()
                            onShowHistory()
                        }
                    }
                    .padding(24)
                }
                .frame(width: 400)
                .background(SettingsBg)
                .transition(.move(edge: .trailing))
            }
        }
        .animation(.easeInOut(duration: 0.3), value: visible)
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title.uppercased())
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(color)
            .tracking(2)
    }

    private func settingsLabel(_ label: String) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DimColor)
        }
    }

    private func settingsRow(
        icon: String,
        iconColor: Color,
        label: String,
        value: String,
        valueColor: Color,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
            Spacer()
            Text(value)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(valueColor)
        }
        .padding(16)
        .background(SettingsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { action() }
    }
}
