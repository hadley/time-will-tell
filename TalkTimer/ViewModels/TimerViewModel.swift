import SwiftUI
import Combine

class TimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
    @Published var status: TimerStatus = .idle
    @Published var currentZone: TimerZone = .black
    @Published var isFlashWhite: Bool = false

    var totalMinutes: Int = 20
    var yellowThresholdMinutes: Int = 5
    var redThresholdMinutes: Int = 2

    private var timerCancellable: AnyCancellable?
    private var flashCancellable: AnyCancellable?
    private let hapticManager = HapticManager()

    var displayText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    init() {
        remainingSeconds = totalMinutes * 60
        updateZone()
    }

    func configure(totalMinutes: Int, yellowThreshold: Int, redThreshold: Int) {
        self.totalMinutes = totalMinutes
        self.yellowThresholdMinutes = yellowThreshold
        self.redThresholdMinutes = redThreshold
        reset()
    }

    func start() {
        status = .running
        startTimer()
    }

    func pause() {
        status = .paused
        timerCancellable?.cancel()
    }

    func reset() {
        status = .idle
        timerCancellable?.cancel()
        flashCancellable?.cancel()
        isFlashWhite = false
        remainingSeconds = totalMinutes * 60
        updateZone()
    }

    func toggle() {
        switch status {
        case .idle, .paused:
            start()
        case .running:
            pause()
        case .finished:
            reset()
        }
    }

    private func startTimer() {
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func tick() {
        guard remainingSeconds > 0 else {
            status = .finished
            timerCancellable?.cancel()
            startFlashing()
            hapticManager.zoneTransition()
            return
        }
        remainingSeconds -= 1
        updateZone()
    }

    private func updateZone() {
        let previousZone = currentZone
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60

        if remainingSeconds <= 0 {
            currentZone = .flashing
        } else if minutes < redThresholdMinutes || (minutes == redThresholdMinutes && seconds == 0) {
            currentZone = .red
        } else if minutes < yellowThresholdMinutes || (minutes == yellowThresholdMinutes && seconds == 0) {
            currentZone = .yellow
        } else {
            currentZone = .black
        }

        if previousZone != currentZone {
            if currentZone == .yellow || currentZone == .red {
                hapticManager.zoneTransition()
            }
        }
    }

    private func startFlashing() {
        currentZone = .flashing
        flashCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.isFlashWhite.toggle()
            }
    }
}
