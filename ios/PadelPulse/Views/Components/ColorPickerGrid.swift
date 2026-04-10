import SwiftUI

struct ColorPickerGrid: View {
    let selectedIndex: Int
    let onSelect: (Int) -> Void

    var body: some View {
        HStack(spacing: 10) {
            ForEach(0..<teamColorPresets.count, id: \.self) { index in
                let preset = teamColorPresets[index]
                Circle()
                    .fill(preset.bg)
                    .frame(width: 40, height: 40)
                    .overlay {
                        if index == selectedIndex {
                            Circle()
                                .stroke(.white, lineWidth: 3)
                        }
                    }
                    .onTapGesture { onSelect(index) }
            }
        }
    }
}
