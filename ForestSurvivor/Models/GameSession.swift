import Foundation

struct GameSession {
    var survivalTime: TimeInterval = 0
    var totalCoins: Int = 0
    var totalKills: Int = 0
    var bossesDefeated: Int = 0
    var upgradesPicked: [UpgradeID] = []
    var reviveUsed: Bool = false

    var score: Int {
        return Int(survivalTime) * 10 + totalCoins + totalKills * 5
    }
}
