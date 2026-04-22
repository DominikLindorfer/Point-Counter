import SwiftUI

struct MatchTimerView: View {
    let vm: MatchViewModel

    @Environment(\.layout) private var layout

    var body: some View {
        // Show the timer while the match is active OR paused-with-start-seeded.
        // The second clause keeps the pill visible during the brief window
        // between restoreInProgressMatch() (matchRunning=false, startTime>0)
        // and resumeTimer() firing on scenePhase=.active — otherwise the pill
        // would flicker in/out across a cold launch.
        if vm.matchRunning || vm.matchStartTimeMs > 0 {
            TimelineView(.periodic(from: .now, by: 1.0)) { context in
                let elapsed = vm.matchRunning
                    ? max(0, Int64(context.date.timeIntervalSince1970 * 1000) - vm.matchStartTimeMs)
                    : Int64(0)
                let totalSec = elapsed / 1000
                let min = totalSec / 60
                let sec = totalSec % 60

                HStack(spacing: 6) {
                    Image(systemName: "timer")
                        .foregroundColor(GoldColor)
                        .font(.system(size: layout.timerIcon))
                    Text(String(format: "%d:%02d", min, sec))
                        .foregroundColor(.white)
                        .font(.system(size: layout.timerFont, weight: .bold))
                }
                .padding(.horizontal, layout.toolbarPaddingH)
                .padding(.vertical, layout.toolbarPaddingV)
                .background(ButtonBg)
                .clipShape(Capsule())
                .accessibilityElement(children: .ignore)
                .accessibilityLabel("Match timer, \(min) minutes \(sec) seconds")
            }
        }
    }
}
