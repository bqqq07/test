import Foundation

final class WaveSystem {
    private var lastWaveTime: TimeInterval = 0
    private var lastBossTime: TimeInterval = 0

    var onWaveUpgrade: (() -> Void)?
    var onBossSpawn: (() -> Void)?

    func update(gameTime: TimeInterval) {
        if gameTime - lastWaveTime >= Constants.waveInterval {
            lastWaveTime = gameTime
            onWaveUpgrade?()
        }

        if gameTime > 0 && gameTime - lastBossTime >= Constants.bossInterval {
            lastBossTime = gameTime
            onBossSpawn?()
        }
    }

    func reset() {
        lastWaveTime = 0
        lastBossTime = 0
    }
}
