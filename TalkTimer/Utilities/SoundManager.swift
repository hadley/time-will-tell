import AVFoundation

class SoundManager {
    private var audioPlayer: AVAudioPlayer?

    func playGong() {
        do {
            // Configure audio session for playback even in silent mode
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)

            let url = Bundle.main.url(forResource: "gong", withExtension: "wav")!
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("Failed to play gong sound: \(error)")
        }
    }
}
