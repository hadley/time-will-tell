@testable import TalkTimer
import Testing

struct TimerViewModelTests {
    // MARK: - Display Text Formatting

    @Test(arguments: [
        (0, "00:00"),
        (305, "05:05"),
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
        vm.configure(totalMinutes: 20, yellowThreshold: 5, redThreshold: 2)
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
        vm.configure(totalMinutes: 10, yellowThreshold: 3, redThreshold: 1)
        vm.remainingSeconds = 100
        vm.reset()
        #expect(vm.remainingSeconds == 10 * 60)
    }
}
