import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()
    @Environment(\.scenePhase) private var scenePhase

    @AppStorage("totalSeconds") private var totalSeconds: Int = 20 * 60
    @AppStorage("yellowThresholdSeconds") private var yellowThresholdSeconds: Int = 5 * 60
    @AppStorage("redThresholdSeconds") private var redThresholdSeconds: Int = 2 * 60
    @AppStorage("playGongOnFinish") private var playGongOnFinish: Bool = false

    @State private var showingSettings = false

    private let soundManager = SoundManager()

    var backgroundColor: Color {
        if viewModel.currentZone == .flashing {
            return viewModel.isFlashWhite ? .white : .red
        }
        return viewModel.currentZone.backgroundColor
    }

    var textColor: Color {
        if viewModel.currentZone == .flashing {
            return viewModel.isFlashWhite ? .black : .white
        }
        return viewModel.currentZone.textColor
    }

    var body: some View {
        ZStack {
            backgroundColor
                .ignoresSafeArea()
                .animation(.easeInOut(duration: 0.1), value: viewModel.isFlashWhite)

            VStack {
                ScalableTimerText(
                    text: viewModel.displayText,
                    textColor: textColor
                )

                TimerScrubber(viewModel: viewModel, textColor: textColor)
                    .padding(.horizontal, 40)
                    .padding(.bottom, 20)
            }

            // Floating buttons in top-right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: viewModel.reset) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 24))
                    }
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gear")
                            .font(.system(size: 24))
                    }
                }
                .foregroundColor(textColor.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.top, 10)
                Spacer()
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                totalSeconds: $totalSeconds,
                yellowThresholdSeconds: $yellowThresholdSeconds,
                redThresholdSeconds: $redThresholdSeconds,
                playGongOnFinish: $playGongOnFinish,
                onSave: applySettings
            )
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            NotificationManager.shared.requestAuthorization()
            applySettings()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: totalSeconds) { _ in
            validateThresholds()
        }
        .onChange(of: viewModel.status) { newStatus in
            if newStatus == .finished, playGongOnFinish {
                soundManager.playGong()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            switch newPhase {
            case .active:
                viewModel.handleReturnToForeground()
            case .background:
                viewModel.handleEnterBackground()
            default:
                break
            }
        }
    }

    private func applySettings() {
        validateThresholds()
        viewModel.configure(
            totalSeconds: totalSeconds,
            yellowThresholdSeconds: yellowThresholdSeconds,
            redThresholdSeconds: redThresholdSeconds
        )
    }

    private func validateThresholds() {
        if yellowThresholdSeconds > totalSeconds {
            yellowThresholdSeconds = totalSeconds
        }
        if redThresholdSeconds > yellowThresholdSeconds {
            redThresholdSeconds = yellowThresholdSeconds
        }
    }
}

#Preview {
    TimerView()
}
