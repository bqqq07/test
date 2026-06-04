import Foundation

final class GameManager {
    static let shared = GameManager()

    var currentSession = GameSession()
    var playerStats = PlayerStats()
    var activeUpgradeLevels: [UpgradeID: Int] = [:]

    var isGameRunning: Bool = false
    var isPaused: Bool = false
    var reviveAvailableThisRound: Bool = true

    private init() {}

    func startNewSession() {
        currentSession = GameSession()
        playerStats = PlayerStats()
        activeUpgradeLevels = [:]
        reviveAvailableThisRound = true
        isGameRunning = true
    }

    func endSession() {
        isGameRunning = false
        SaveManager.shared.saveGameSession(currentSession)
    }

    func levelForUpgrade(_ id: UpgradeID) -> Int {
        return activeUpgradeLevels[id] ?? 0
    }

    func applyUpgrade(_ upgrade: UpgradeData) {
        let current = levelForUpgrade(upgrade.id)
        guard current < upgrade.maxLevel else { return }
        activeUpgradeLevels[upgrade.id] = current + 1
        modifyStats(for: upgrade.id)
    }

    private func modifyStats(for id: UpgradeID) {
        switch id {
        case .sharpArrow:    playerStats.attackDamage *= 1.20
        case .quickShot:     playerStats.attackSpeed  *= 1.20
        case .longRange:     playerStats.arrowRange   *= 1.25
        case .multiShot:     playerStats.multiShotCount += 1
        case .pierce:        playerStats.pierceCount   += 1
        case .explosiveTip:  playerStats.hasExplosiveTip = true
        case .poisonArrow:
            playerStats.poisonDamage    = 5
            playerStats.poisonDuration  = 4
        case .forkShot:      playerStats.hasForkShot   = true
        case .boomerang:     playerStats.hasBoomerang   = true
        case .criticalEye:   playerStats.critChance    += 0.10
        case .barkArmor:
            playerStats.maxHP      += 25
            playerStats.currentHP  += 25
        case .forestShield:  playerStats.damageReduction += 0.15
        case .regeneration:  playerStats.regenPerSec   += 3
        case .thornAura:     playerStats.thornAuraDamage += 5
        case .secondWind:    playerStats.hasSecondWind  = true
        case .swiftBoots:    playerStats.moveSpeed      *= 1.15
        case .coinMagnet:    playerStats.pickupRadius   *= 1.60
        case .blink:         playerStats.hasBlink        = true
        }
    }
}
