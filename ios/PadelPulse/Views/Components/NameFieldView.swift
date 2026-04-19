import SwiftUI

struct NameFieldView: View {
    @Binding var text: String

    @Environment(\.layout) private var layout
    @State private var showLimitReached = false

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            TextField("", text: $text)
                .onChange(of: text) { _, newValue in
                    if newValue.count > 16 {
                        text = String(newValue.prefix(16))
                        showLimitReached = true
                        Task {
                            try? await Task.sleep(for: .seconds(2))
                            await MainActor.run {
                                withAnimation { showLimitReached = false }
                            }
                        }
                    }
                }
                .font(.system(size: layout.nameFieldFont, weight: .bold))
                .foregroundColor(.white)
                .padding(16)
                .background(SettingsSurface)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityLabel("Team name")

            if showLimitReached {
                Text("Max 16 characters")
                    .font(.system(size: 11))
                    .foregroundColor(RecordRed)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: showLimitReached)
    }
}
