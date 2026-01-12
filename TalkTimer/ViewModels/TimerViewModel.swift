import Combine
import SwiftUI

func zoneForTime(seconds: Int, yellowThreshold: Int, redThreshold: Int) -> TimerZone {
    if seconds <= 0 {
        .flashing
    } else if seconds <= redThreshold {
        .red
    } else if seconds <= yellowThreshold {
        .yellow
    } else {
        .black
    }
}

class TimerViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0 {
        didSet {
            updateZone()
        }
    }

    @Published var status: TimerStatus = .idle
    @Published var currentZone: TimerZone = .black
    @Published var isFlashWhite: Bool = false

    var totalSeconds: Int = 20 * 60
    var yellowThresholdSeconds: Int = 5 * 60
    var redThresholdSeconds: Int = 2 * 60

    private var timerCancellable: AnyCancellable?
    private var flashCancellable: AnyCancellable?
    private let hapticManager = HapticManager()

    // For background time tracking
    private(set) var timerStartDate: Date?
    private(set) var remainingSecondsAtStart: Int = 0

    var displayText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%2d:%02d", minutes, seconds)
    }

    init() {
        remainingSeconds = totalSeconds
        updateZone()
    }

    func configure(totalSeconds: Int, yellowThresholdSeconds: Int, redThresholdSeconds: Int) {
        self.totalSeconds = totalSeconds
        self.yellowThresholdSeconds = yellowThresholdSeconds
        self.redThresholdSeconds = redThresholdSeconds
        reset()
    }

    func start() {
        status = .running
        timerStartDate = Date()
        remainingSecondsAtStart = remainingSeconds
        startTimer()
    }

    func pause() {
        status = .paused
        timerCancellable?.cancel()
        flashCancellable?.cancel()
        isFlashWhite = false
        timerStartDate = nil
    }

    func reset() {
        status = .idle
        timerCancellable?.cancel()
        flashCancellable?.cancel()
        isFlashWhite = false
        timerStartDate = nil
        remainingSeconds = totalSeconds
        updateZone()
    }

    func handleReturnToForeground(now: Date = Date()) {
        // Cancel background notifications since we're back in foreground
        NotificationManager.shared.cancelAllNotifications()

        guard status == .running, let startDate = timerStartDate else { return }

        let elapsedSeconds = Int(now.timeIntervalSince(startDate))
        let newRemaining = max(0, remainingSecondsAtStart - elapsedSeconds)

        remainingSeconds = newRemaining

        if remainingSeconds <= 0 {
            status = .finished
            timerCancellable?.cancel()
            startFlashing()
            hapticManager.zoneTransition()
        }
    }

    func handleEnterBackground() {
        guard status == .running else { return }

        NotificationManager.shared.scheduleTimerNotifications(
            remainingSeconds: remainingSeconds,
            yellowThreshold: yellowThresholdSeconds,
            redThreshold: redThresholdSeconds
        )
    }

    func toggle() {
        switch status {
        case .idle, .paused:
            start()
        case .running, .finished:
            pause()
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
        currentZone = zoneForTime(
            seconds: remainingSeconds,
            yellowThreshold: yellowThresholdSeconds,
            redThreshold: redThresholdSeconds
        )

        if previousZone != currentZone, currentZone != .black {
            hapticManager.zoneTransition()
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
