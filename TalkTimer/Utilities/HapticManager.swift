import CoreHaptics
import OSLog
import UIKit

protocol HapticManaging {
    func zoneTransition()
}

final class HapticManager {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TalkTimer", category: "HapticManager")
    private var engine: CHHapticEngine?

    init() {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else { return }

        do {
            engine = try CHHapticEngine()
            try engine?.start()

            // Restart engine if it stops
            engine?.resetHandler = { [weak self] in
                try? self?.engine?.start()
            }
        } catch {
            logger.error("Haptic engine failed to start: \(String(describing: error))")
        }
    }

    func zoneTransition() {
        guard let engine else { return }

        // Create a continuous buzz pattern
        let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
        let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)

        let buzz = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 0.6)

        do {
            let pattern = try CHHapticPattern(events: [buzz], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
        } catch {
            logger.error("Failed to play haptic: \(String(describing: error))")
        }
    }
}

extension HapticManager: HapticManaging {}
