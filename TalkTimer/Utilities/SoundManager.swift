import AVFoundation
import OSLog

protocol SoundPlaying {
    func playGong()
}

final class SoundManager {
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "TalkTimer", category: "SoundManager")
    private var audioPlayer: AVAudioPlayer?

    func playGong() {
        do {
            // Configure audio session for playback even in silent mode
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            guard let url = Bundle.main.url(forResource: "gong", withExtension: "wav") else {
                logger.error("Missing gong.wav in main bundle; cannot play gong.")
                return
            }
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            logger.error("Failed to play gong sound: \(String(describing: error))")
        }
    }
}

extension SoundManager: SoundPlaying {}
