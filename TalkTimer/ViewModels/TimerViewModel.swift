import Combine
import OSLog
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

final class TimerViewModel: ObservableObject {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TalkTimer", category: "TimerViewModel")

    @Published private(set) var remainingSeconds: Int = 0 {
        didSet {
            updateZone()
        }
    }

    @Published private(set) var status: TimerStatus = .idle
    @Published private(set) var currentZone: TimerZone = .black
    @Published var isFlashWhite: Bool = false

    var totalSeconds: Int = 20 * 60
    var yellowThresholdSeconds: Int = 5 * 60
    var redThresholdSeconds: Int = 2 * 60

    private var timerCancellable: AnyCancellable?
    private var flashCancellable: AnyCancellable?
    private let hapticManager: any HapticManaging
    private let notificationManager: any NotificationManaging
    private let timeProvider: any ElapsedTimeProviding

    // Monotonic deadline in `timeProvider` seconds. When nil, timer isn't running.
    private var deadline: TimeInterval?

    var displayText: String {
        let minutes = remainingSeconds / 60
        let seconds = remainingSeconds % 60
        return String(format: "%2d:%02d", minutes, seconds)
    }

    init(
        timeProvider: any ElapsedTimeProviding = ContinuousUptimeElapsedTimeProvider(),
        hapticManager: any HapticManaging = HapticManager(),
        notificationManager: any NotificationManaging = NotificationManager.shared
    ) {
        self.timeProvider = timeProvider
        self.hapticManager = hapticManager
        self.notificationManager = notificationManager
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
        stopFlashing()
        deadline = timeProvider.now + TimeInterval(remainingSeconds)
        startTimer()
        recomputeRemaining()
    }

    func pause() {
        // Capture an accurate remaining time before stopping.
        recomputeRemaining()
        status = .paused
        timerCancellable?.cancel()
        timerCancellable = nil
        stopFlashing()
        deadline = nil
    }

    func reset() {
        status = .idle
        timerCancellable?.cancel()
        timerCancellable = nil
        stopFlashing()
        deadline = nil
        remainingSeconds = totalSeconds
        updateZone()
    }

    func handleReturnToForeground() {
        // Cancel background notifications since we're back in foreground
        notificationManager.cancelAllNotifications()

        guard status == .running else { return }
        recomputeRemaining()
        startTimer()
    }

    func handleEnterBackground() {
        guard status == .running else { return }
        recomputeRemaining()

        notificationManager.scheduleTimerNotifications(
            remainingSeconds: remainingSeconds,
            yellowThreshold: yellowThresholdSeconds,
            redThreshold: redThresholdSeconds
        )
    }

    func scrub(toRemainingSeconds newRemainingSeconds: Int) {
        let clamped = min(max(newRemainingSeconds, 0), totalSeconds)

        switch status {
        case .running:
            // Keep the deadline consistent with the user's chosen remaining time.
            deadline = timeProvider.now + TimeInterval(clamped)
            remainingSeconds = clamped

            if clamped <= 0 {
                transitionToFinishedIfNeeded()
            }

        case .finished:
            // User is adjusting time after finishing; stop flashing and move to a paused state.
            stopFlashing()
            deadline = nil
            status = .paused
            remainingSeconds = clamped

        case .paused, .idle:
            remainingSeconds = clamped
        }
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
        guard status == .running else { return }
        // Avoid creating multiple timers when returning from background.
        if timerCancellable != nil { return }
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.recomputeRemaining()
            }
    }

    /// Recompute `remainingSeconds` from the monotonic deadline, ensuring there is no drift.
    func recomputeRemaining() {
        guard status == .running else { return }
        guard let deadline else {
            logger.error("Timer is running but deadline is nil; pausing to recover.")
            forcePause()
            return
        }

        let secondsLeft = deadline - timeProvider.now
        let newRemaining = max(0, Int(ceil(secondsLeft)))

        if newRemaining != remainingSeconds {
            remainingSeconds = newRemaining
        }

        if newRemaining <= 0 {
            transitionToFinishedIfNeeded()
        }
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

    private func transitionToFinishedIfNeeded() {
        guard status != .finished else { return }
        status = .finished
        timerCancellable?.cancel()
        timerCancellable = nil
        deadline = nil
        startFlashing()
    }

    private func startFlashing() {
        currentZone = .flashing
        flashCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.isFlashWhite.toggle()
            }
    }

    private func stopFlashing() {
        flashCancellable?.cancel()
        flashCancellable = nil
        isFlashWhite = false
    }

    private func forcePause() {
        status = .paused
        timerCancellable?.cancel()
        timerCancellable = nil
        stopFlashing()
        deadline = nil
    }
}
