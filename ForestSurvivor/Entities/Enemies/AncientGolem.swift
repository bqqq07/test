import SpriteKit

final class AncientGolem: Enemy {
    enum Phase { case one, two }
    private(set) var phase: Phase = .one

    private var rockTimer: TimeInterval = 0
    private let rockInterval: TimeInterval = 8.0
    var onRockAttack: ((_ targetPos: CGPoint) -> Void)?

    init() {
        super.init(type: .ancientGolem)
        sprite.size = EnemyData.ancientGolem.size
    }
    required init?(coder: NSCoder) { fatalError() }

    override func update(delta: TimeInterval, playerPosition: CGPoint) {
        super.update(delta: delta, playerPosition: playerPosition)

        let hpPct = currentHP / maxHP
        if hpPct < 0.5 && phase == .one {
            phase = .two
            data = EnemyData(
                type: .ancientGolem,
                baseHP: data.baseHP,
                armor: data.armor,
                moveSpeed: data.moveSpeed * 1.2,
                damagePerSec: data.damagePerSec,
                coins: data.coins,
                xp: data.xp,
                spawnAfterSeconds: data.spawnAfterSeconds,
                size: data.size
            )
        }

        rockTimer += delta
        if rockTimer >= rockInterval {
            rockTimer = 0
            let randomOffset = CGPoint(x: CGFloat.random(in: -50...50),
                                       y: CGFloat.random(in: -50...50))
            onRockAttack?(playerPosition + randomOffset)
        }
    }
}
