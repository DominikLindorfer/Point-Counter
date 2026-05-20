import SwiftUI

/// Pre-match overlay that lets the user pick who serves first — either by
/// tapping a team tile or by pressing the team's Bluetooth-remote button.
/// Shown after `New Match` (and on fresh launches) when the
/// `askForServerBeforeMatch` setting is on.
///
/// While visible, the remote's team buttons route into
/// `MatchViewModel.pickServingTeam`, and Play/Pause calls `swapSides()` so
/// users can flip the iPad's left/right panel assignment from the court
/// (without walking back). The background handles tap-outside dismiss.
struct ServePickOverlayView: View {
    let vm: MatchViewModel

    @Environment(\.layout) private var layout

    var body: some View {
        // Resolve left/right against sidesSwapped so the tile the user taps
        // matches the court side they're looking at. Reads of `sidesSwapped`
        // propagate through @Observable, so the swap button re-renders the
        // tiles in place on every flip.
        let team1OnLeft = !vm.sidesSwapped
        let leftTeam = team1OnLeft ? 1 : 2
        let rightTeam = team1OnLeft ? 2 : 1
        let leftName = team1OnLeft ? vm.team1Name : vm.team2Name
        let rightName = team1OnLeft ? vm.team2Name : vm.team1Name
        let leftColor = team1OnLeft ? vm.team1Color : vm.team2Color
        let rightColor = team1OnLeft ? vm.team2Color : vm.team1Color

        ZStack {
            // Background absorbs taps outside the content stack and dismisses
            // the overlay. contentShape makes the full Color hit-testable.
            Color.black.opacity(0.88)
                .ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { vm.dismissServePick() }

            VStack(spacing: 28) {
                VStack(spacing: 10) {
                    Text("WHO SERVES FIRST?")
                        .font(.system(size: layout.matchOverTitleFont, weight: .bold))
                        .foregroundColor(GoldColor)
                        .tracking(4)
                        .multilineTextAlignment(.center)

                    Text("Tap a team or press a remote button · Play/Pause flips sides")
                        .font(.system(size: layout.matchOverButtonFont))
                        .foregroundColor(DimColor)
                        .multilineTextAlignment(.center)
                }

                HStack(spacing: 0) {
                    serveTile(
                        name: leftName,
                        color: leftColor,
                        side: "LEFT",
                        team: leftTeam
                    )

                    swapButton

                    serveTile(
                        name: rightName,
                        color: rightColor,
                        side: "RIGHT",
                        team: rightTeam
                    )
                }
                .animation(.easeInOut(duration: 0.25), value: vm.sidesSwapped)

                Button(action: { vm.dismissServePick() }) {
                    Text("SKIP")
                        .font(.system(size: layout.matchOverButtonFont, weight: .bold))
                        .foregroundColor(DimColor)
                        .tracking(2)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(DimColor.opacity(0.4), lineWidth: 1)
                        )
                }
                .accessibilityLabel("Skip serve pick")
            }
            .padding(.horizontal, 40)
        }
        .transition(.opacity)
    }

    private var swapButton: some View {
        Button(action: {
            HapticService.settingChanged()
            vm.swapSides()
        }) {
            Image(systemName: "arrow.left.arrow.right")
                .font(.system(size: layout.toolbarIconSize * 1.6, weight: .bold))
                .foregroundColor(GoldColor)
                .frame(width: 64, height: 64)
                .background(Color.white.opacity(0.08))
                .clipShape(Circle())
                .overlay(Circle().stroke(GoldColor.opacity(0.5), lineWidth: 1.5))
                .padding(.horizontal, 16)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Swap sides")
    }

    private func serveTile(name: String, color: Color, side: LocalizedStringKey, team: Int) -> some View {
        Button(action: { vm.pickServingTeam(team) }) {
            VStack(spacing: 14) {
                Text(side)
                    .font(.system(size: layout.servingBadgeFont, weight: .heavy))
                    .foregroundColor(GoldColor)
                    .tracking(3)

                Image(systemName: "tennisball.fill")
                    .font(.system(size: layout.matchOverTitleFont))
                    .foregroundColor(color.contrastingTextColor)

                Text(name)
                    .font(.system(size: layout.teamNameFont, weight: .bold))
                    .foregroundColor(color.contrastingTextColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                    .padding(.horizontal, 8)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 32)
            .padding(.horizontal, 20)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 24))
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(GoldColor.opacity(0.3), lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text("\(name), serve first"))
    }
}
