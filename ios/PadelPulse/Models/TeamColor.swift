import SwiftUI
import UIKit

/// Default team colors.
let defaultTeam1Color = Color(red: 0x1B / 255.0, green: 0x3A / 255.0, blue: 0x5C / 255.0)
let defaultTeam2Color = Color(red: 0x8B / 255.0, green: 0x2D / 255.0, blue: 0x2D / 255.0)

extension Color {
    /// Returns white or black depending on the luminance of the color.
    var contrastingTextColor: Color {
        let components = rgbComponents
        let luminance = 0.299 * components[0] + 0.587 * components[1] + 0.114 * components[2]
        return luminance > 0.55 ? .black : .white
    }

    /// Extracts RGB components as [r, g, b] (0.0–1.0).
    var rgbComponents: [CGFloat] {
        let uiColor = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        return [r, g, b]
    }

    /// Creates a Color from [r, g, b] components (0.0–1.0).
    init(rgb: [CGFloat]) {
        self.init(
            red: Double(rgb.count > 0 ? rgb[0] : 0),
            green: Double(rgb.count > 1 ? rgb[1] : 0),
            blue: Double(rgb.count > 2 ? rgb[2] : 0)
        )
    }
}
