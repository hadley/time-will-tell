import AVFoundation
import OSLog

protocol SoundPlaying {
    func playGong()
}

final class SoundManager {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TalkTimer", category: "SoundManager")
    private var audioPlayer: AVAudioPlayer?

    init() {
        prepareGong()
    }

    func prepareGong() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            guard let url = Bundle.main.url(forResource: "gong", withExtension: "wav") else {
                logger.error("Missing gong.wav in main bundle; cannot play gong.")
                return
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
        } catch {
            logger.error("Failed to prepare gong sound: \(String(describing: error))")
        }
    }

    func playGong() {
        guard let audioPlayer else {
            logger.error("Audio player not prepared; cannot play gong.")
            return
        }
        audioPlayer.currentTime = 0
        audioPlayer.play()
        // Re-prepare for next playback
        audioPlayer.prepareToPlay()
    }
}

extension SoundManager: SoundPlaying {}
