import CoreGraphics
import Foundation

struct Constants {
    static let mapSize = CGSize(width: 2000, height: 2000)
    static let waveInterval: TimeInterval = 60.0
    static let bossInterval: TimeInterval = 300.0
    static let reviveHPPercentage: Float = 0.5
    static let maxEnemiesOnScreen = 80

    struct ZPositions {
        static let background: CGFloat = -10
        static let ground: CGFloat = -5
        static let decorations: CGFloat = -3
        static let entities: CGFloat = 0
        static let particles: CGFloat = 5
        static let hud: CGFloat = 10
    }

    struct Player {
        static let maxHP: Float = 100
        static let moveSpeed: CGFloat = 180
        static let attackDamage: Float = 20
        static let attackSpeed: Float = 1.0
        static let arrowRange: CGFloat = 280
        static let arrowSpeed: CGFloat = 500
        static let pickupRadius: CGFloat = 60
        static let critChance: Float = 0.05
        static let critMultiplier: Float = 2.0
    }

    struct Wave {
        static let hpMultiplier: Float = 1.15
        static let speedMultiplier: Float = 1.05
        static let spawnMultiplier: Float = 0.93
        static let countIncrease: Int = 2
    }

    struct Fonts {
        static let primary = "PressStart2P-Regular"
        static let body = "VT323-Regular"
    }

    struct Colors {
        static let hpGreen = "#2ECC71"
        static let hpYellow = "#F1C40F"
        static let hpRed = "#E74C3C"
        static let coinGold = "#F4D03F"
        static let uiBackground = "#1C1C2E"
        static let textPrimary = "#F0EDE8"
    }
}
