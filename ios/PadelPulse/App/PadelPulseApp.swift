import SwiftUI

@main
struct PadelPulseApp: App {
    @State private var viewModel = MatchViewModel(storage: MatchStorage())
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage(LanguageService.storageKey) private var selectedLanguage = "system"
    private let remoteInput = RemoteInputService()

    init() {
        LanguageService.applyStoredLanguage()
    }

    var body: some Scene {
        WindowGroup {
            GeometryReader { geo in
                ContentView(vm: viewModel)
                    .environment(\.layout, LayoutMetrics(
                        screenWidth: geo.size.width,
                        screenHeight: geo.size.height
                    ))
                    .id(selectedLanguage)
            }
            .statusBarHidden()
            .persistentSystemOverlays(.hidden)
            .onAppear {
                UIApplication.shared.isIdleTimerDisabled = true
                setupRemoteInput()
                viewModel.restoreInProgressMatch()
            }
        }
        .commands {
            CommandGroup(replacing: .undoRedo) {
                Button("Undo") { viewModel.undo() }
                    .keyboardShortcut("z", modifiers: .command)
                    .disabled(!viewModel.canUndo)
            }
            CommandGroup(replacing: .newItem) {
                Button("New Match") { viewModel.resetMatch() }
                    .keyboardShortcut("n", modifiers: .command)
            }
            CommandMenu("Match") {
                Button("Swap Sides") { HapticService.settingChanged(); viewModel.swapSides() }
                    .keyboardShortcut("s", modifiers: .command)
            }
        }
        .onChange(of: scenePhase) { _, newPhase in
            switch newPhase {
            case .background, .inactive:
                // Pause first so a subsequent kill (OOM, long time in app switcher)
                // restores with an accurate elapsed time rather than wall-clock delta.
                viewModel.pauseTimer()
                viewModel.saveInProgressMatch()
            case .active:
                viewModel.resumeTimer()
                remoteInput.resumeSilentLoop()
            default:
                break
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
    @State private var showCredits = false

    var body: some View {
        ZStack {
            if showHistory {
                MatchHistoryView(vm: vm, onBack: { showHistory = false })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else if showCredits {
                CreditsView(onClose: { showCredits = false })
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                ScoreBoardView(
                    vm: vm,
                    onShowHistory: { showHistory = true },
                    onShowCredits: { showCredits = true }
                )
                .transition(.asymmetric(
                    insertion: .move(edge: .leading).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))
            }
        }
        .animation(.easeInOut(duration: 0.35), value: showHistory)
        .animation(.easeInOut(duration: 0.35), value: showCredits)
    }
}
