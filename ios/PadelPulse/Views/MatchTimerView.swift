import SwiftUI

struct MatchTimerView: View {
    let vm: MatchViewModel

    var body: some View {
        if vm.matchRunning || vm.matchStartTimeMs > 0 {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let elapsed: Int64
                if vm.matchRunning {
                    elapsed = Int64(context.date.timeIntervalSince1970 * 1000) - vm.matchStartTimeMs
                } else {
                    elapsed = 0
                }
                let totalSec = max(0, elapsed / 1000)
                let min = totalSec / 60
                let sec = totalSec % 60

                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(GoldColor)
                        .font(.system(size: 20))
                    Text(String(format: "%d:%02d", min, sec))
                        .foregroundColor(.white)
                        .font(.system(size: 14, weight: .bold))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(ButtonBg)
                .clipShape(Capsule())
            }
        }
    }
}
