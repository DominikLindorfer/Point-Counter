import SwiftUI

struct ColorSwatchPicker: View {
    @Binding var selection: Color

    static let presets: [Color] = [
        Color(red: 0x1B / 255.0, green: 0x3A / 255.0, blue: 0x5C / 255.0), // Navy
        Color(red: 0x8B / 255.0, green: 0x2D / 255.0, blue: 0x2D / 255.0), // Crimson
        Color(red: 0x2D / 255.0, green: 0x7A / 255.0, blue: 0x4A / 255.0), // Forest
        Color(red: 0x5C / 255.0, green: 0x2D / 255.0, blue: 0x8B / 255.0), // Purple
        Color(red: 0x2D / 255.0, green: 0x6B / 255.0, blue: 0x6B / 255.0), // Teal
        Color(red: 0x8B / 255.0, green: 0x6B / 255.0, blue: 0x1B / 255.0), // Amber
        Color(red: 0x3D / 255.0, green: 0x3D / 255.0, blue: 0x3D / 255.0), // Graphite
        Color(red: 0x8B / 255.0, green: 0x2D / 255.0, blue: 0x6B / 255.0), // Rose
    ]

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<Self.presets.count, id: \.self) { index in
                let preset = Self.presets[index]
                let selected = colorMatches(selection, preset)

                Circle()
                    .fill(preset)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: selected ? 2.5 : 0)
                    )
                    .overlay(
                        Group {
                            if selected {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .onTapGesture {
                        selection = preset
                        HapticService.settingChanged()
                    }
            }
        }
    }

    private func colorMatches(_ a: Color, _ b: Color) -> Bool {
        let ac = a.rgbComponents
        let bc = b.rgbComponents
        return abs(ac[0] - bc[0]) < 0.05 && abs(ac[1] - bc[1]) < 0.05 && abs(ac[2] - bc[2]) < 0.05
    }
}
