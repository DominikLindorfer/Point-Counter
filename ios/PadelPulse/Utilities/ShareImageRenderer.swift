import SwiftUI

/// Renders a MatchScoreCardView to a UIImage for sharing.
enum ShareImageRenderer {
    @MainActor
    static func render(match: SavedMatch) -> UIImage? {
        let view = MatchScoreCardView(match: match)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 2.0
        return renderer.uiImage
    }
}
