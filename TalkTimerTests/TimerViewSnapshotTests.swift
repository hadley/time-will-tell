import SnapshotTesting
import SwiftUI
@testable import TalkTimer
import Testing

/// Test wrapper that displays a timer with specific text
private struct TimerSnapshotView: View {
    let displayText: String

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ScalableTimerText(text: displayText, textColor: .white)
        }
    }
}

@MainActor
struct TimerViewSnapshotTests {
    @Test func timerDisplaySizing() {
        let view = TimerView()

        // iPhone landscape
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13ProMax(.landscape))),
            named: "iPhone"
        )

        // iPad landscape
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPadPro12_9(.landscape))),
            named: "iPad"
        )
    }

    @Test func narrowTimerDisplay() {
        let view = TimerSnapshotView(displayText: " 1:11")

        // iPhone landscape
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPhone13ProMax(.landscape))),
            named: "iPhone"
        )

        // iPad landscape
        assertSnapshot(
            of: view,
            as: .image(layout: .device(config: .iPadPro12_9(.landscape))),
            named: "iPad"
        )
    }
}
