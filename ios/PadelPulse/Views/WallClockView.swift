import SwiftUI

struct WallClockView: View {
    @Environment(\.layout) private var layout

    var body: some View {
        TimelineView(.periodic(from: .now, by: 30.0)) { context in
            HStack(spacing: 6) {
                Image(systemName: "clock")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.system(size: layout.timerIcon))
                Text(context.date.formatted(date: .omitted, time: .shortened))
                    .foregroundColor(.white)
                    .font(.system(size: layout.timerFont, weight: .bold))
                    .monospacedDigit()
            }
            .padding(.horizontal, layout.toolbarPaddingH)
            .padding(.vertical, layout.toolbarPaddingV)
            .background(ButtonBg)
            .clipShape(Capsule())
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(context.date, style: .time))
        }
    }
}
