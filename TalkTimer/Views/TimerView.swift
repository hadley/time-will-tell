import SwiftUI

struct TimerView: View {
    @StateObject private var viewModel = TimerViewModel()

    @AppStorage("totalMinutes") private var totalMinutes: Int = 20
    @AppStorage("yellowThreshold") private var yellowThreshold: Int = 5
    @AppStorage("redThreshold") private var redThreshold: Int = 2

    @State private var showingSettings = false

    var backgroundColor: Color {
        if viewModel.currentZone == .flashing {
            return viewModel.isFlashWhite ? .white : .red
        }
        return viewModel.currentZone.backgroundColor
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                backgroundColor
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.1), value: viewModel.isFlashWhite)

                HStack {
                    Spacer()
                    ScalableTimerText(
                        text: viewModel.displayText,
                        textColor: viewModel.currentZone.textColor,
                        geometry: geometry
                    )
                    Spacer()

                    VStack(spacing: 40) {
                        Button(action: viewModel.toggle) {
                            Image(systemName: playPauseIcon)
                                .font(.system(size: 36))
                        }

                        Button(action: viewModel.reset) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 36))
                        }

                        Button(action: { showingSettings = true }) {
                            Image(systemName: "gear")
                                .font(.system(size: 36))
                        }
                    }
                    .foregroundColor(viewModel.currentZone.textColor.opacity(0.7))
                    .padding(.trailing, 40)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView(
                totalMinutes: $totalMinutes,
                yellowThreshold: $yellowThreshold,
                redThreshold: $redThreshold,
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
    }

    private var playPauseIcon: String {
        switch viewModel.status {
        case .running:
            return "pause.fill"
        case .finished:
            return "arrow.counterclockwise"
        default:
            return "play.fill"
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
