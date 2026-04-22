import SwiftUI

struct SettingsSidebarView: View {
    let visible: Bool
    let vm: MatchViewModel
    let onClose: () -> Void
    var onShowHistory: () -> Void = {}
    var onShowCredits: () -> Void = {}

    @Environment(\.layout) private var layout
    @AppStorage(DefaultsKey.cameraOverlayEnabled) private var cameraEnabled = false
    @AppStorage(DefaultsKey.askForServerBeforeMatch) private var askForServer = true
    @AppStorage(LanguageService.storageKey) private var selectedLanguage = "system"

    private var languageDisplayName: String {
        switch selectedLanguage {
        case "en": return "English"
        case "de": return "Deutsch"
        case "es": return "Español"
        default: return "Auto"
        }
    }

    private var languageBinding: Binding<String> {
        Binding(
            get: { selectedLanguage },
            set: { new in
                // Swizzle the bundle before updating @AppStorage so the .id-driven
                // refresh on ContentView sees the new bundle on first render.
                LanguageService.apply(languageCode: new)
                selectedLanguage = new
                HapticService.settingChanged()
            }
        )
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

                        toggleRow(
                            icon: "hand.raised.fill",
                            label: "Ask Who Serves",
                            isOn: Binding(
                                get: { askForServer },
                                set: { askForServer = $0; HapticService.settingChanged() }
                            )
                        )

                        Spacer().frame(height: 10)

                        toggleRow(
                            icon: "arrow.left.arrow.right",
                            label: "Serve Side (L/R)",
                            isOn: Binding(
                                get: { vm.showServeSide },
                                set: { vm.showServeSide = $0; HapticService.settingChanged() }
                            )
                        )

                        Spacer().frame(height: 10)

                        toggleRow(
                            iconOn: "speaker.wave.2.fill",
                            iconOff: "speaker.slash.fill",
                            label: "Sound Effects",
                            isOn: Binding(
                                get: { !SoundService.isMuted },
                                set: { SoundService.isMuted = !$0; HapticService.settingChanged() }
                            )
                        )

                        Spacer().frame(height: 10)

                        toggleRow(
                            iconOn: "video.fill",
                            iconOff: "video.slash.fill",
                            label: "Camera",
                            isOn: Binding(
                                get: { cameraEnabled },
                                set: { cameraEnabled = $0; HapticService.settingChanged() }
                            )
                        )

                        Spacer().frame(height: 10)

                        // Language switcher — Menu with Picker so users pick directly
                        // instead of cycling through states blind.
                        Menu {
                            Picker(selection: languageBinding) {
                                Text(verbatim: "Auto").tag("system")
                                Text(verbatim: "English").tag("en")
                                Text(verbatim: "Deutsch").tag("de")
                                Text(verbatim: "Español").tag("es")
                            } label: {
                                Text("Language")
                            }
                        } label: {
                            languageRowLabel
                        }

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

    /// Settings-row styled label for the language Menu (mirrors settingsRow visually).
    private var languageRowLabel: some View {
        let active = selectedLanguage != "system"
        return HStack {
            HStack(spacing: 12) {
                Image(systemName: "globe")
                    .font(.system(size: layout.settingsRowIcon))
                    .foregroundColor(active ? GoldColor : DimColor)
                Text("Language")
                    .font(.system(size: layout.settingsRowLabel))
                    .foregroundColor(.white)
            }
            Spacer()
            HStack(spacing: 8) {
                Text(verbatim: languageDisplayName)
                    .font(.system(size: layout.settingsRowValue, weight: .bold))
                    .foregroundColor(active ? GoldColor : DimColor)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                Image(systemName: "chevron.up.chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(DimColor.opacity(0.5))
            }
        }
        .padding(16)
        .background(SettingsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    /// Single-icon toggle row (icon stays the same, color follows state).
    private func toggleRow(
        icon: String,
        label: LocalizedStringKey,
        isOn: Binding<Bool>
    ) -> some View {
        toggleRow(iconOn: icon, iconOff: icon, label: label, isOn: isOn)
    }

    /// Two-icon toggle row (icon swaps between on/off state).
    private func toggleRow(
        iconOn: String,
        iconOff: String,
        label: LocalizedStringKey,
        isOn: Binding<Bool>
    ) -> some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: isOn.wrappedValue ? iconOn : iconOff)
                    .font(.system(size: layout.settingsRowIcon))
                    .foregroundColor(isOn.wrappedValue ? GoldColor : DimColor)
                Text(label)
                    .font(.system(size: layout.settingsRowLabel))
                    .foregroundColor(.white)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(GoldColor)
        }
        .padding(16)
        .background(SettingsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
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
