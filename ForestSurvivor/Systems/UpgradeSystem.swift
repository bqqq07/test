import Foundation

final class UpgradeSystem {
    static func pickThreeUpgrades() -> [UpgradeData] {
        let gm = GameManager.shared
        var available = UpgradeData.all.filter { upgrade in
            gm.levelForUpgrade(upgrade.id) < upgrade.maxLevel
        }

        var picked: [UpgradeData] = []
        var attempts = 0

        while picked.count < 3 && !available.isEmpty && attempts < 100 {
            attempts += 1
            guard let candidate = weightedRandom(from: available) else { break }
            available.removeAll { $0.id == candidate.id }
            picked.append(candidate)
        }

        return picked
    }

    private static func weightedRandom(from items: [UpgradeData]) -> UpgradeData? {
        let total = items.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return items.randomElement() }
        var r = Int.random(in: 0..<total)
        for item in items {
            r -= item.weight
            if r < 0 { return item }
        }
        return items.last
    }
}
