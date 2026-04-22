import SwiftUI

struct ColorSwatchPicker: View {
    @Binding var selection: Color

    /// Each preset ships its pre-built SwiftUI Color plus its RGB components,
    /// so we don't rebuild UIColor(color).getRed(...) on every render.
    private struct Preset {
        let color: Color
        let components: [CGFloat]
    }

    private static let presets: [Preset] = [
        preset(r: 0x1B, g: 0x3A, b: 0x5C), // Navy
        preset(r: 0x8B, g: 0x2D, b: 0x2D), // Crimson
        preset(r: 0x2D, g: 0x7A, b: 0x4A), // Forest
        preset(r: 0x5C, g: 0x2D, b: 0x8B), // Purple
        preset(r: 0x2D, g: 0x6B, b: 0x6B), // Teal
        preset(r: 0x8B, g: 0x6B, b: 0x1B), // Amber
        preset(r: 0x3D, g: 0x3D, b: 0x3D), // Graphite
        preset(r: 0x8B, g: 0x2D, b: 0x6B), // Rose
    ]

    private static func preset(r: Int, g: Int, b: Int) -> Preset {
        let rf = CGFloat(r) / 255.0
        let gf = CGFloat(g) / 255.0
        let bf = CGFloat(b) / 255.0
        return Preset(color: Color(red: rf, green: gf, blue: bf), components: [rf, gf, bf])
    }

    var body: some View {
        // Compute selection components once per render, not once per preset.
        let selectionComponents = selection.rgbComponents

        HStack(spacing: 10) {
            ForEach(0..<Self.presets.count, id: \.self) { index in
                let preset = Self.presets[index]
                let selected = componentsMatch(preset.components, selectionComponents)

                Circle()
                    .fill(preset.color)
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
                        selection = preset.color
                        HapticService.settingChanged()
                    }
            }
        }
    }

    private func componentsMatch(_ a: [CGFloat], _ b: [CGFloat]) -> Bool {
        guard a.count >= 3, b.count >= 3 else { return false }
        return abs(a[0] - b[0]) < 0.05 && abs(a[1] - b[1]) < 0.05 && abs(a[2] - b[2]) < 0.05
    }
}
