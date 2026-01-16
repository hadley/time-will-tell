import Foundation
@testable import TalkTimer
import Testing

// MARK: - Pure Zone Function

@Test(arguments: [
    (301, 300, 120, TimerZone.black), // 1 sec above yellow
    (300, 300, 120, TimerZone.yellow), // exactly at yellow
    (121, 300, 120, TimerZone.yellow), // 1 sec above red
    (120, 300, 120, TimerZone.red), // exactly at red
    (1, 300, 120, TimerZone.red), // 1 sec left
    (0, 300, 120, TimerZone.flashing), // time's up
])
func zoneForTimeTests(seconds: Int, yellow: Int, red: Int, expected: TimerZone) {
    #expect(zoneForTime(seconds: seconds, yellowThreshold: yellow, redThreshold: red) == expected)
}

// MARK: - Test Doubles

final class FakeElapsedTimeProvider: ElapsedTimeProviding {
    var now: TimeInterval = 0

    func advance(by seconds: TimeInterval) {
        now += seconds
    }
}

struct NoopHapticManager: HapticManaging {
    func zoneTransition() {}
}

final class NoopNotificationManager: NotificationManaging {
    func requestAuthorization() {}

    func scheduleTimerNotifications(remainingSeconds _: Int, yellowThreshold _: Int, redThreshold _: Int) {}

    func cancelAllNotifications() {}
}

struct TimerViewModelTests {
    // MARK: - Display Text Formatting

    @Test(arguments: [
        (0, " 0:00"),
        (305, " 5:05"),
        (600, "10:00"),
        (5999, "99:59"),
    ])
    func displayText(seconds: Int, expected: String) {
        let vm = TimerViewModel(
            timeProvider: FakeElapsedTimeProvider(),
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        // Allow the larger formatting case (e.g. 99:59).
        vm.configure(totalSeconds: 100 * 60, yellowThresholdSeconds: 5 * 60, redThresholdSeconds: 2 * 60)
        vm.scrub(toRemainingSeconds: seconds)
        #expect(vm.displayText == expected)
    }

    // MARK: - Zone Transitions

    @Test(arguments: [
        (360, TimerZone.black), // 6 min
        (300, TimerZone.yellow), // 5 min
        (180, TimerZone.yellow), // 3 min
        (120, TimerZone.red), // 2 min
        (60, TimerZone.red), // 1 min
        (0, TimerZone.flashing),
    ])
    func zoneTransitions(seconds: Int, expectedZone: TimerZone) {
        let vm = TimerViewModel(
            timeProvider: FakeElapsedTimeProvider(),
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 20 * 60, yellowThresholdSeconds: 5 * 60, redThresholdSeconds: 2 * 60)
        vm.scrub(toRemainingSeconds: seconds)
        #expect(vm.currentZone == expectedZone)
    }

    // MARK: - Timer State Management

    @Test func initialStatusIsIdle() {
        #expect(
            TimerViewModel(
                timeProvider: FakeElapsedTimeProvider(),
                hapticManager: NoopHapticManager(),
                notificationManager: NoopNotificationManager()
            ).status == .idle
        )
    }

    @Test func startPauseReset() {
        let vm = TimerViewModel(
            timeProvider: FakeElapsedTimeProvider(),
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )

        vm.start()
        #expect(vm.status == .running)

        vm.pause()
        #expect(vm.status == .paused)

        vm.reset()
        #expect(vm.status == .idle)
    }

    @Test func toggle() {
        let vm = TimerViewModel(
            timeProvider: FakeElapsedTimeProvider(),
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )

        vm.toggle()
        #expect(vm.status == .running)

        vm.toggle()
        #expect(vm.status == .paused)

        vm.toggle()
        #expect(vm.status == .running)
    }

    @Test func resetRestoresFullTime() {
        let vm = TimerViewModel(
            timeProvider: FakeElapsedTimeProvider(),
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.scrub(toRemainingSeconds: 100)
        vm.reset()
        #expect(vm.remainingSeconds == 10 * 60)
    }

    // MARK: - Background Time Tracking

    @Test func handleReturnToForegroundUpdatesRemainingTime() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        // Simulate 5 minutes passing while in background
        time.advance(by: 5 * 60)
        vm.handleReturnToForeground()

        #expect(vm.remainingSeconds == 5 * 60)
        #expect(vm.status == .running)
    }

    @Test func handleReturnToForegroundFinishesWhenTimeExpired() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 5 * 60, yellowThresholdSeconds: 2 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        // Simulate 10 minutes passing (more than total time)
        time.advance(by: 10 * 60)
        vm.handleReturnToForeground()

        #expect(vm.remainingSeconds == 0)
        #expect(vm.status == .finished)
        #expect(vm.currentZone == .flashing)
    }

    @Test func handleReturnToForegroundDoesNothingWhenPaused() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()
        vm.pause()

        let originalRemaining = vm.remainingSeconds
        time.advance(by: 5 * 60)
        vm.handleReturnToForeground()

        #expect(vm.remainingSeconds == originalRemaining)
        #expect(vm.status == .paused)
    }

    @Test func handleReturnToForegroundDoesNothingWhenIdle() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)

        let originalRemaining = vm.remainingSeconds
        time.advance(by: 5 * 60)
        vm.handleReturnToForeground()

        #expect(vm.remainingSeconds == originalRemaining)
        #expect(vm.status == .idle)
    }

    @Test func handleReturnToForegroundUpdatesZone() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        #expect(vm.currentZone == .black)

        // Simulate 8 minutes passing - should now be in yellow zone (2 min remaining)
        time.advance(by: 8 * 60)
        vm.handleReturnToForeground()

        #expect(vm.remainingSeconds == 2 * 60)
        #expect(vm.currentZone == .yellow)
    }

    // MARK: - Drift / Deadline Behavior

    @Test func recomputeRemainingCatchesUpAfterDelay() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        // No intermediate recompute calls (simulates a stalled runloop / missed ticks).
        time.advance(by: 12)
        vm.recomputeRemaining()

        #expect(vm.remainingSeconds == (10 * 60) - 12)
        #expect(vm.status == .running)
    }

    @Test func scrubbingWhileRunningKeepsDeadlineConsistent() {
        let time = FakeElapsedTimeProvider()
        let vm = TimerViewModel(
            timeProvider: time,
            hapticManager: NoopHapticManager(),
            notificationManager: NoopNotificationManager()
        )
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        // Simulate some time passing.
        time.advance(by: 60)
        vm.recomputeRemaining()
        #expect(vm.remainingSeconds == 9 * 60)

        // User scrubs to 100s remaining while still running.
        vm.scrub(toRemainingSeconds: 100)
        #expect(vm.remainingSeconds == 100)

        // Countdown should now be based on the new remaining time, not the old deadline.
        time.advance(by: 10)
        vm.recomputeRemaining()
        #expect(vm.remainingSeconds == 90)
    }
}
