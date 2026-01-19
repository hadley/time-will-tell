import Foundation
import Darwin.Mach

/// Abstraction over a monotonic time source expressed in seconds.
///
/// This is intentionally *not* wall-clock `Date` time so that changes to the
/// user's clock / timezone / NTP adjustments cannot skew the countdown.
protocol ElapsedTimeProviding {
    /// Current time in seconds from an arbitrary monotonic reference.
    var now: TimeInterval { get }
}

/// Monotonic, continuous time since boot (includes time spent asleep).
///
/// Backed by `mach_continuous_time`, which is stable across foreground/background
/// and is not affected by wall-clock changes.
final class ContinuousUptimeElapsedTimeProvider: ElapsedTimeProviding {
    private let timebase: mach_timebase_info_data_t

    init() {
        var info = mach_timebase_info_data_t()
        mach_timebase_info(&info)
        timebase = info
    }

    var now: TimeInterval {
        let ticks = mach_continuous_time()
        let nanos = (Double(ticks) * Double(timebase.numer)) / Double(timebase.denom)
        return nanos / 1_000_000_000
    }
}

