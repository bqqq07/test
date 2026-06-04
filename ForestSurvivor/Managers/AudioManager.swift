import AVFoundation
import SpriteKit

final class AudioManager {
    static let shared = AudioManager()

    var isMuted: Bool = false {
        didSet { bgmPlayer?.volume = isMuted ? 0 : bgmVolume }
    }
    var bgmVolume: Float = 0.5 {
        didSet { bgmPlayer?.volume = isMuted ? 0 : bgmVolume }
    }
    var sfxVolume: Float = 0.8

    private var bgmPlayer: AVAudioPlayer?
    private var currentBGM: String = ""

    private init() {
        isMuted = SaveManager.shared.isMuted
        bgmVolume = SaveManager.shared.bgmVolume
        sfxVolume = SaveManager.shared.sfxVolume
    }

    func playSFX(_ name: String, on node: SKNode) {
        guard !isMuted else { return }
        let action = SKAction.playSoundFileNamed(name, waitForCompletion: false)
        node.run(action)
    }

    func playBGM(_ name: String) {
        guard !isMuted, currentBGM != name else { return }
        currentBGM = name
        guard let url = Bundle.main.url(forResource: name, withExtension: nil) else { return }
        bgmPlayer?.stop()
        bgmPlayer = try? AVAudioPlayer(contentsOf: url)
        bgmPlayer?.numberOfLoops = -1
        bgmPlayer?.volume = bgmVolume
        bgmPlayer?.play()
    }

    func stopBGM() {
        bgmPlayer?.stop()
        currentBGM = ""
    }

    func pauseBGM() { bgmPlayer?.pause() }
    func resumeBGM() { if !isMuted { bgmPlayer?.play() } }
}
