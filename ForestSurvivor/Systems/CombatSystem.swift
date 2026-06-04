import SpriteKit

final class CombatSystem {
    weak var scene: SKScene?

    var onEnemyKilled: ((Enemy) -> Void)?
    var onPlayerDamaged: ((Float) -> Void)?
    var onExplosion: ((CGPoint, CGFloat, [Enemy]) -> Void)?
    var onForkArrow: ((Arrow, CGPoint) -> Void)?

    func handleArrowHitEnemy(arrow: Arrow, enemy: Enemy) {
        guard arrow.hitEnemies.insert(ObjectIdentifier(enemy)).inserted else { return }

        let isCrit = Float.random(in: 0...1) < GameManager.shared.playerStats.critChance
        let damage = arrow.damage * (isCrit ? GameManager.shared.playerStats.critMultiplier : 1.0)

        let killed = enemy.takeDamage(damage)
        showDamageNumber(Int(damage), at: enemy.position, isCrit: isCrit)

        if arrow.hasPoison && !killed {
            applyPoison(to: enemy, dps: arrow.poisonDamage, duration: arrow.poisonDuration)
        }

        if arrow.hasExplosive {
            onExplosion?(enemy.position, arrow.explosiveRadius, [enemy])
        }

        if arrow.hasFork {
            onForkArrow?(arrow, enemy.position)
        }

        if killed { onEnemyKilled?(enemy) }

        if arrow.hitEnemies.count >= arrow.pierceCount {
            arrow.removeFromParent()
        }
    }

    func handlePlayerTouchEnemy(player: Player, enemy: Enemy, delta: TimeInterval) {
        guard enemy.isAlive else { return }
        let dmg = enemy.contactDamagePerSec * Float(delta)
        onPlayerDamaged?(dmg)

        if let vine = enemy as? VineCreature {
            player.applySlow(multiplier: 0.7, duration: 2.0)
        }
    }

    func applyThornAura(player: Player, enemies: [Enemy], delta: TimeInterval) {
        guard player.stats.thornAuraDamage > 0 else { return }
        let radius = player.stats.thornAuraRadius
        let dps    = player.stats.thornAuraDamage
        for enemy in enemies where enemy.isAlive {
            if enemy.position.distance(to: player.position) <= radius {
                if enemy.takeDamage(dps * Float(delta)) {
                    onEnemyKilled?(enemy)
                }
            }
        }
    }

    private func applyPoison(to enemy: Enemy, dps: Float, duration: Float) {
        var remaining = duration
        let tick = SKAction.repeatForever(.sequence([
            .wait(forDuration: 0.5),
            .run { [weak enemy, weak self] in
                guard let enemy = enemy, enemy.isAlive else { return }
                remaining -= 0.5
                if enemy.takeDamage(dps * 0.5) {
                    self?.onEnemyKilled?(enemy)
                }
                if remaining <= 0 { enemy.removeAction(forKey: "poison") }
            }
        ]))
        enemy.run(tick, withKey: "poison")
    }

    // MARK: - Floating Damage Numbers

    func showDamageNumber(_ damage: Int, at position: CGPoint, isCrit: Bool) {
        guard let scene = scene else { return }
        let label = SKLabelNode(text: isCrit ? "⚡\(damage)" : "\(damage)")
        label.fontName  = Constants.Fonts.primary
        label.fontSize  = isCrit ? 20 : 14
        label.fontColor = isCrit ? .yellow : .white
        label.position  = position
        label.zPosition = Constants.ZPositions.particles
        scene.addChild(label)

        let up     = SKAction.moveBy(x: CGFloat.random(in: -15...15), y: 40, duration: 0.6)
        let fade   = SKAction.fadeOut(withDuration: 0.3)
        let remove = SKAction.removeFromParent()
        label.run(.sequence([up, .group([fade]), remove]))
    }
}
