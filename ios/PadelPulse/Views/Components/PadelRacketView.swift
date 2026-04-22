import SwiftUI

/// Padel racket icon.
/// Source: "padel" by Rusma Ratri Handini from Noun Project (CC BY 3.0)
/// https://thenounproject.com/browse/icons/term/padel/
struct PadelRacketView: View {
    let color: Color
    let size: CGFloat

    var body: some View {
        Image("PadelRacket")
            .resizable()
            .renderingMode(.template)
            .aspectRatio(contentMode: .fit)
            .foregroundColor(color)
            .frame(width: size, height: size)
    }
}
