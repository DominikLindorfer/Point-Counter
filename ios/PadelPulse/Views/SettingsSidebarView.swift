import SwiftUI

struct SettingsSidebarView: View {
    let visible: Bool
    let vm: MatchViewModel
    let onClose: () -> Void
    var onShowHistory: () -> Void = {}
    var onShowCredits: () -> Void = {}

    @Environment(\.layout) private var layout
    @AppStorage(DefaultsKey.cameraOverlayEnabled) private var cameraEnabled = false
    @AppStorage(LanguageService.storageKey) private var selectedLanguage = "system"

    private var languageDisplayName: String {
        switch selectedLanguage {
        case "en": return "English"
        case "de": return "Deutsch"
        case "es": return "Español"
        default: return "Auto"
        }
    }

    private func cycleLanguage() {
        let order = ["system"] + LanguageService.supportedLanguages
        let idx = order.firstIndex(of: selectedLanguage) ?? 0
        let next = order[(idx + 1) % order.count]
        selectedLanguage = next
        LanguageService.apply(languageCode: next)
    }

    var body: some View {
        let team1Accent = vm.team1Color.contrastingTextColor
        let team2Accent = vm.team2Color.contrastingTextColor
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
                                    .font(.system(size: layout.settingsHeaderIcon))
                                    .foregroundColor(.white)
                                Text("SETTINGS")
                                    .font(.system(size: layout.settingsHeaderFont, weight: .bold))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Button(action: onClose) {
                                Image(systemName: "xmark")
                                    .font(.system(size: layout.settingsHeaderIcon))
                                    .foregroundColor(.white)
                            }
                            .keyboardShortcut(.escape, modifiers: [])
                        }

                        Spacer().frame(height: 24)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 20)

                        // Team 1
                        sectionHeader("Team 1", color: team1Accent)
                        Spacer().frame(height: 16)
                        settingsLabel("Name")
                        Spacer().frame(height: 6)
                        NameFieldView(text: Binding(
                            get: { vm.team1Name },
                            set: { vm.updateTeam1Name($0) }
                        ))
                        Spacer().frame(height: 16)
                        settingsLabel("Color")
                        Spacer().frame(height: 6)
                        ColorSwatchPicker(selection: Binding(
                            get: { vm.team1Color },
                            set: { vm.updateTeam1Color($0) }
                        ))

                        Spacer().frame(height: 28)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 24)

                        // Team 2
                        sectionHeader("Team 2", color: team2Accent)
                        Spacer().frame(height: 16)
                        settingsLabel("Name")
                        Spacer().frame(height: 6)
                        NameFieldView(text: Binding(
                            get: { vm.team2Name },
                            set: { vm.updateTeam2Name($0) }
                        ))
                        Spacer().frame(height: 16)
                        settingsLabel("Color")
                        Spacer().frame(height: 6)
                        ColorSwatchPicker(selection: Binding(
                            get: { vm.team2Color },
                            set: { vm.updateTeam2Color($0) }
                        ))

                        Spacer().frame(height: 28)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 24)

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

                        Spacer().frame(height: 10)

                        // Sets to win
                        settingsRow(
                            icon: "repeat",
                            iconColor: DimColor,
                            label: "Sets to Win",
                            value: vm.setsToWin == 0 ? "NO LIMIT" : "\(vm.setsToWin)",
                            valueColor: .white
                        ) { vm.cycleSetsToWin() }

                        Spacer().frame(height: 10)

                        // Auto side-swap
                        settingsRow(
                            icon: "arrow.left.arrow.right.square",
                            iconColor: vm.autoSwapMode == .off ? DimColor : GoldColor,
                            label: "Auto Side Swap",
                            value: vm.autoSwapMode == .off ? "OFF" : "AFTER SET",
                            valueColor: vm.autoSwapMode == .off ? DimColor : GoldColor
                        ) { vm.cycleAutoSwapMode() }

                        Spacer().frame(height: 10)

                        // First serve
                        let serveName = vm.servingTeam == 1 ? vm.team1Name : vm.team2Name
                        let serveColor = vm.servingTeam == 1 ? team1Accent : team2Accent
                        let serveBgColor = vm.servingTeam == 1 ? vm.team1Color : vm.team2Color
                        settingsRow(
                            icon: "tennisball.fill",
                            iconColor: DimColor,
                            label: "Serving",
                            value: "\(serveName)",
                            valueColor: serveColor,
                            teamColorDot: serveBgColor
                        ) { vm.updateServingTeam(vm.servingTeam == 1 ? 2 : 1) }

                        Spacer().frame(height: 10)

                        // Serve side indicator toggle
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: "arrow.left.arrow.right")
                                    .font(.system(size: layout.settingsRowIcon))
                                    .foregroundColor(vm.showServeSide ? GoldColor : DimColor)
                                Text("Serve Side (L/R)")
                                    .font(.system(size: layout.settingsRowLabel))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { vm.showServeSide },
                                set: { vm.showServeSide = $0; HapticService.settingChanged() }
                            ))
                            .labelsHidden()
                            .tint(GoldColor)
                        }
                        .padding(16)
                        .background(SettingsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer().frame(height: 10)

                        // Sound effects toggle
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: SoundService.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                                    .font(.system(size: layout.settingsRowIcon))
                                    .foregroundColor(SoundService.isMuted ? DimColor : GoldColor)
                                Text("Sound Effects")
                                    .font(.system(size: layout.settingsRowLabel))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { !SoundService.isMuted },
                                set: { SoundService.isMuted = !$0; HapticService.settingChanged() }
                            ))
                            .labelsHidden()
                            .tint(GoldColor)
                        }
                        .padding(16)
                        .background(SettingsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer().frame(height: 10)

                        // Camera overlay toggle
                        HStack {
                            HStack(spacing: 12) {
                                Image(systemName: cameraEnabled ? "video.fill" : "video.slash.fill")
                                    .font(.system(size: layout.settingsRowIcon))
                                    .foregroundColor(cameraEnabled ? GoldColor : DimColor)
                                Text("Camera")
                                    .font(.system(size: layout.settingsRowLabel))
                                    .foregroundColor(.white)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { cameraEnabled },
                                set: { cameraEnabled = $0; HapticService.settingChanged() }
                            ))
                            .labelsHidden()
                            .tint(GoldColor)
                        }
                        .padding(16)
                        .background(SettingsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                        Spacer().frame(height: 10)

                        // Language switcher
                        settingsRow(
                            icon: "globe",
                            iconColor: selectedLanguage == "system" ? DimColor : GoldColor,
                            label: "Language",
                            value: LocalizedStringKey(languageDisplayName),
                            valueColor: selectedLanguage == "system" ? DimColor : GoldColor
                        ) { cycleLanguage() }

                        Spacer().frame(height: 28)
                        Divider().background(Color(white: 0.2))
                        Spacer().frame(height: 20)

                        // Match history button
                        HStack(spacing: 12) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: layout.settingsRowIcon))
                                .foregroundColor(GoldColor)
                            Text("Match History")
                                .font(.system(size: layout.settingsRowLabel))
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

                        Spacer().frame(height: 10)

                        // Credits
                        HStack(spacing: 12) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: layout.settingsRowIcon))
                                .foregroundColor(GoldColor)
                            Text("Credits")
                                .font(.system(size: layout.settingsRowLabel))
                                .foregroundColor(.white)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                        .background(SettingsSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .onTapGesture {
                            onClose()
                            onShowCredits()
                        }
                    }
                    .padding(28)
                }
                .frame(width: layout.settingsWidth)
                .background(SettingsBg)
                .transition(.move(edge: .trailing))
                .gesture(
                    DragGesture(minimumDistance: 30, coordinateSpace: .local)
                        .onEnded { value in
                            if value.translation.width > 80 {
                                onClose()
                            }
                        }
                )
            }
        }
        .animation(.easeInOut(duration: 0.3), value: visible)
    }

    private func sectionHeader(_ title: String, color: Color) -> some View {
        Text(title.uppercased())
            .font(.system(size: layout.settingsSectionFont, weight: .bold))
            .foregroundColor(color)
            .tracking(2)
    }

    private func settingsLabel(_ label: LocalizedStringKey) -> some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(DimColor)
        }
    }

    private func settingsRow(
        icon: String,
        iconColor: Color,
        label: LocalizedStringKey,
        value: LocalizedStringKey,
        valueColor: Color,
        teamColorDot: Color? = nil,
        action: @escaping () -> Void
    ) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: layout.settingsRowIcon))
                    .foregroundColor(iconColor)
                Text(label)
                    .font(.system(size: layout.settingsRowLabel))
                    .foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 8) {
                if let dotColor = teamColorDot {
                    Circle()
                        .fill(dotColor)
                        .frame(width: 10, height: 10)
                }
                Text(value)
                    .font(.system(size: layout.settingsRowValue, weight: .bold))
                    .foregroundColor(valueColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DimColor.opacity(0.5))
            }
        }
        .padding(16)
        .background(SettingsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .onTapGesture { HapticService.settingChanged(); action() }
        .accessibilityAddTraits(.isButton)
    }
}
