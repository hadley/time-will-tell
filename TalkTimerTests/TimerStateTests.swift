import SwiftUI
@testable import TalkTimer
import Testing

struct TimerStateTests {
    @Test(arguments: [
        (TimerZone.black, Color.black, Color.white),
        (TimerZone.yellow, Color.yellow, Color.black),
        (TimerZone.red, Color.red, Color.white),
        (TimerZone.flashing, Color.red, Color.white),
    ])
    func zoneColors(zone: TimerZone, expectedBackground: Color, expectedText: Color) {
        #expect(zone.backgroundColor == expectedBackground)
        #expect(zone.textColor == expectedText)
    }
}
