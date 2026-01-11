import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()

    @AppStorage("totalMinutes") private var totalMinutes: Int = 20
    @AppStorage("yellowThreshold") private var yellowThreshold: Int = 5
    @AppStorage("redThreshold") private var redThreshold: Int = 2
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
                totalMinutes: $totalMinutes,
                yellowThreshold: $yellowThreshold,
                redThreshold: $redThreshold,
                playGongOnFinish: $playGongOnFinish,
                onSave: applySettings
            )
        }
        .onAppear {
            UIApplication.shared.isIdleTimerDisabled = true
            applySettings()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .onChange(of: totalMinutes) { _ in
            validateThresholds()
        }
        .onChange(of: viewModel.status) { newStatus in
            if newStatus == .finished, playGongOnFinish {
                soundManager.playGong()
            }
        }
    }

    private func applySettings() {
        validateThresholds()
        viewModel.configure(
            totalMinutes: totalMinutes,
            yellowThreshold: yellowThreshold,
            redThreshold: redThreshold
        )
    }

    private func validateThresholds() {
        if yellowThreshold > totalMinutes {
            yellowThreshold = totalMinutes
        }
        if redThreshold > yellowThreshold {
            redThreshold = yellowThreshold
        }
    }
}

#Preview {
    TimerView()
}
