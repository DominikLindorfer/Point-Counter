import SwiftUI

struct CreditsView: View {
    let onClose: () -> Void

    @Environment(\.layout) private var layout
    @Environment(\.openURL) private var openURL

    var body: some View {
        ZStack {
            DarkBg.ignoresSafeArea()

            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    HStack(spacing: 12) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: layout.settingsHeaderIcon))
                            .foregroundColor(GoldColor)
                        Text("CREDITS")
                            .font(.system(size: layout.settingsHeaderFont, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(2)
                    }
                    Spacer()
                    Button(action: onClose) {
                        Image(systemName: "xmark")
                            .font(.system(size: layout.settingsHeaderIcon))
                            .foregroundColor(.white)
                    }
                    .accessibilityLabel("Back to scoreboard")
                    .keyboardShortcut(.escape, modifiers: [])
                }
                .padding(.horizontal, 28)
                .padding(.top, 28)

                Spacer().frame(height: 24)
                Divider().background(Color(white: 0.2)).padding(.horizontal, 28)
                Spacer().frame(height: 24)

                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        creditCard(
                            icon: "chevron.left.forwardslash.chevron.right",
                            title: "Based on",
                            body: "Point-Counter by Dominik Lindorfer",
                            linkLabel: "github.com/DominikLindorfer/Point-Counter",
                            url: "https://github.com/DominikLindorfer/Point-Counter"
                        )

                        creditCard(
                            icon: "paintbrush.pointed.fill",
                            title: "Padel racket icon",
                            body: "\"padel\" by Rusma Ratri Handini from Noun Project (CC BY 3.0)",
                            linkLabel: "thenounproject.com/browse/icons/term/padel",
                            url: "https://thenounproject.com/browse/icons/term/padel/"
                        )

                        Spacer().frame(height: 8)

                        Text("Made with love for padel.")
                            .font(.system(size: layout.settingsRowValue))
                            .foregroundColor(DimColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.horizontal, 28)
                    .padding(.bottom, 28)
                }
            }
        }
    }

    private func creditCard(
        icon: String,
        title: LocalizedStringKey,
        body: LocalizedStringKey,
        linkLabel: String,
        url: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: layout.settingsRowIcon))
                    .foregroundColor(GoldColor)
                Text(title)
                    .font(.system(size: layout.settingsSectionFont, weight: .bold))
                    .foregroundColor(.white)
            }
            Text(body)
                .font(.system(size: layout.settingsRowLabel))
                .foregroundColor(.white.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
            Button(action: {
                if let u = URL(string: url) { openURL(u) }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.system(size: layout.settingsRowValue))
                    Text(linkLabel)
                        .font(.system(size: layout.settingsRowValue, weight: .medium))
                }
                .foregroundColor(GoldColor)
            }
            .accessibilityLabel(linkLabel)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(SettingsSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
