import CoreGraphics
import Foundation

struct PlayerStats {
    var maxHP: Float = Constants.Player.maxHP
    var currentHP: Float = Constants.Player.maxHP
    var moveSpeed: CGFloat = Constants.Player.moveSpeed
    var attackDamage: Float = Constants.Player.attackDamage
    var attackSpeed: Float = Constants.Player.attackSpeed       // arrows/sec
    var arrowRange: CGFloat = Constants.Player.arrowRange
    var arrowSpeed: CGFloat = Constants.Player.arrowSpeed
    var pickupRadius: CGFloat = Constants.Player.pickupRadius
    var critChance: Float = Constants.Player.critChance
    var critMultiplier: Float = Constants.Player.critMultiplier

    var coins: Int = 0
    var kills: Int = 0

    var multiShotCount: Int = 1     // 1 = single, 2+ = multi
    var pierceCount: Int = 1        // how many enemies one arrow can hit
    var hasExplosiveTip: Bool = false
    var explosiveRadius: CGFloat = 60
    var poisonDamage: Float = 0     // per second
    var poisonDuration: Float = 0
    var hasForkShot: Bool = false
    var hasBoomerang: Bool = false
    var thornAuraDamage: Float = 0
    var thornAuraRadius: CGFloat = 80
    var hasSecondWind: Bool = false
    var secondWindUsed: Bool = false
    var hasBlink: Bool = false
    var regenPerSec: Float = 0
    var damageReduction: Float = 0  // 0.0 to 1.0

    var attackInterval: TimeInterval { TimeInterval(1.0 / attackSpeed) }

    mutating func applyHealing(_ amount: Float) {
        currentHP = min(currentHP + amount, maxHP)
    }

    mutating func applyDamage(_ amount: Float) -> Bool {
        let reduced = amount * (1.0 - damageReduction)
        if hasSecondWind && !secondWindUsed && (currentHP - reduced) <= 0 {
            secondWindUsed = true
            currentHP = 1
            return false
        }
        currentHP -= reduced
        return currentHP <= 0
    }
}
