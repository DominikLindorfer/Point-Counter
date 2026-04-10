import SwiftUI

@main
struct PadelPulseApp: App {
    @State private var viewModel = MatchViewModel(storage: MatchStorage())
    private let remoteInput = RemoteInputService()

    var body: some Scene {
        WindowGroup {
            ContentView(vm: viewModel)
                .statusBarHidden()
                .persistentSystemOverlays(.hidden)
                .onAppear {
                    UIApplication.shared.isIdleTimerDisabled = true
                    setupRemoteInput()
                }
        }
    }

    private func setupRemoteInput() {
        remoteInput.onTeam1Score = { [viewModel] in viewModel.scorePoint(team: 1) }
        remoteInput.onTeam2Score = { [viewModel] in viewModel.scorePoint(team: 2) }
        remoteInput.onUndo = { [viewModel] in viewModel.undo() }
        remoteInput.start()
    }
}

struct ContentView: View {
    let vm: MatchViewModel
    @State private var showHistory = false

    var body: some View {
        if showHistory {
            MatchHistoryView(vm: vm, onBack: { showHistory = false })
        } else {
            ScoreBoardView(vm: vm, onShowHistory: { showHistory = true })
        }
    }
}
