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

struct TimerViewModelTests {
    // MARK: - Display Text Formatting

    @Test(arguments: [
        (0, " 0:00"),
        (305, " 5:05"),
        (600, "10:00"),
        (5999, "99:59"),
    ])
    func displayText(seconds: Int, expected: String) {
        let vm = TimerViewModel()
        vm.remainingSeconds = seconds
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
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 20 * 60, yellowThresholdSeconds: 5 * 60, redThresholdSeconds: 2 * 60)
        vm.remainingSeconds = seconds
        #expect(vm.currentZone == expectedZone)
    }

    // MARK: - Timer State Management

    @Test func initialStatusIsIdle() {
        #expect(TimerViewModel().status == .idle)
    }

    @Test func startPauseReset() {
        let vm = TimerViewModel()

        vm.start()
        #expect(vm.status == .running)

        vm.pause()
        #expect(vm.status == .paused)

        vm.reset()
        #expect(vm.status == .idle)
    }

    @Test func toggle() {
        let vm = TimerViewModel()

        vm.toggle()
        #expect(vm.status == .running)

        vm.toggle()
        #expect(vm.status == .paused)

        vm.toggle()
        #expect(vm.status == .running)
    }

    @Test func resetRestoresFullTime() {
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.remainingSeconds = 100
        vm.reset()
        #expect(vm.remainingSeconds == 10 * 60)
    }

    // MARK: - Background Time Tracking

    @Test func handleReturnToForegroundUpdatesRemainingTime() {
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        // Simulate 5 minutes passing while in background
        let fiveMinutesLater = Date().addingTimeInterval(5 * 60)
        vm.handleReturnToForeground(now: fiveMinutesLater)

        #expect(vm.remainingSeconds == 5 * 60)
        #expect(vm.status == .running)
    }

    @Test func handleReturnToForegroundFinishesWhenTimeExpired() {
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 5 * 60, yellowThresholdSeconds: 2 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        // Simulate 10 minutes passing (more than total time)
        let tenMinutesLater = Date().addingTimeInterval(10 * 60)
        vm.handleReturnToForeground(now: tenMinutesLater)

        #expect(vm.remainingSeconds == 0)
        #expect(vm.status == .finished)
        #expect(vm.currentZone == .flashing)
    }

    @Test func handleReturnToForegroundDoesNothingWhenPaused() {
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()
        vm.pause()

        let originalRemaining = vm.remainingSeconds
        let fiveMinutesLater = Date().addingTimeInterval(5 * 60)
        vm.handleReturnToForeground(now: fiveMinutesLater)

        #expect(vm.remainingSeconds == originalRemaining)
        #expect(vm.status == .paused)
    }

    @Test func handleReturnToForegroundDoesNothingWhenIdle() {
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)

        let originalRemaining = vm.remainingSeconds
        let fiveMinutesLater = Date().addingTimeInterval(5 * 60)
        vm.handleReturnToForeground(now: fiveMinutesLater)

        #expect(vm.remainingSeconds == originalRemaining)
        #expect(vm.status == .idle)
    }

    @Test func handleReturnToForegroundUpdatesZone() {
        let vm = TimerViewModel()
        vm.configure(totalSeconds: 10 * 60, yellowThresholdSeconds: 3 * 60, redThresholdSeconds: 1 * 60)
        vm.start()

        #expect(vm.currentZone == .black)

        // Simulate 8 minutes passing - should now be in yellow zone (2 min remaining)
        let eightMinutesLater = Date().addingTimeInterval(8 * 60)
        vm.handleReturnToForeground(now: eightMinutesLater)

        #expect(vm.remainingSeconds == 2 * 60)
        #expect(vm.currentZone == .yellow)
    }
}
