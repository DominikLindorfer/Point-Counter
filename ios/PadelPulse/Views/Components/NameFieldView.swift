import SwiftUI

struct NameFieldView: View {
    @Binding var text: String

    var body: some View {
        TextField("", text: $text)
            .onChange(of: text) { _, newValue in
                if newValue.count > 16 {
                    text = String(newValue.prefix(16))
                }
            }
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .padding(16)
            .background(SettingsSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
