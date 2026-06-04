import SpriteKit

final class SpawnSystem {
    weak var scene: SKScene?
    private var spawnTimer: TimeInterval = 0
    private var waveMultiplier: Int = 1

    var onSpawnEnemy: ((Enemy) -> Void)?

    func update(delta: TimeInterval, gameTime: TimeInterval) {
        spawnTimer += delta
        let interval = currentSpawnInterval(gameTime: gameTime)
        if spawnTimer >= interval {
            spawnTimer = 0
            spawnWave(gameTime: gameTime)
        }
    }

    private func currentSpawnInterval(gameTime: TimeInterval) -> TimeInterval {
        let base = 2.0
        let reduction = min(gameTime / 120.0, 0.6)
        return base * (1.0 - reduction)
    }

    private func spawnWave(gameTime: TimeInterval) {
        let count = 1 + Int(gameTime / 30)
        let type  = pickEnemyType(gameTime: gameTime)
        let hp    = waveHPMultiplier(gameTime: gameTime)

        for _ in 0..<min(count, Constants.maxEnemiesOnScreen) {
            let enemy = createEnemy(type: type)
            enemy.waveHPMultiplier = hp
            enemy.currentHP = enemy.maxHP * hp
            enemy.position = randomEdgePosition()
            onSpawnEnemy?(enemy)
        }
    }

    private func pickEnemyType(gameTime: TimeInterval) -> EnemyType {
        var pool: [EnemyType] = [.wolf]
        if gameTime >= 90  { pool += [.boar] }
        if gameTime >= 120 { pool += [.bat] }
        if gameTime >= 180 { pool += [.troll] }
        if gameTime >= 240 { pool += [.vineCreature] }
        return pool.randomElement()!
    }

    private func waveHPMultiplier(gameTime: TimeInterval) -> Float {
        let waves = Int(gameTime / 60)
        return pow(Constants.Wave.hpMultiplier, Float(waves))
    }

    private func createEnemy(type: EnemyType) -> Enemy {
        switch type {
        case .wolf:         return Wolf()
        case .bat:          return Bat()
        case .boar:         return Boar()
        case .vineCreature: return VineCreature()
        case .troll:        return Troll()
        case .ancientGolem: return AncientGolem()
        }
    }

    private func randomEdgePosition() -> CGPoint {
        let margin: CGFloat = 60
        let w = Constants.mapSize.width
        let h = Constants.mapSize.height
        switch Int.random(in: 0..<4) {
        case 0: return CGPoint(x: CGFloat.random(in: 0...w), y: -margin)
        case 1: return CGPoint(x: CGFloat.random(in: 0...w), y: h + margin)
        case 2: return CGPoint(x: -margin, y: CGFloat.random(in: 0...h))
        default: return CGPoint(x: w + margin, y: CGFloat.random(in: 0...h))
        }
    }
}
