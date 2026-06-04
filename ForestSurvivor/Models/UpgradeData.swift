import Foundation

enum UpgradeRarity {
    case common, uncommon, rare
}

enum UpgradeID: String, CaseIterable {
    // Attack
    case sharpArrow
    case quickShot
    case longRange
    case multiShot
    case pierce
    case explosiveTip
    case poisonArrow
    case forkShot
    case boomerang
    case criticalEye

    // Defense
    case barkArmor
    case forestShield
    case regeneration
    case thornAura
    case secondWind

    // Utility
    case swiftBoots
    case coinMagnet
    case blink
}

struct UpgradeData {
    let id: UpgradeID
    let name: String
    let icon: String
    let description: String
    let maxLevel: Int
    let rarity: UpgradeRarity
    let weight: Int

    static let all: [UpgradeData] = [
        // Attack
        UpgradeData(id: .sharpArrow,   name: "Sharp Arrow",   icon: "🏹",  description: "+20% Damage",              maxLevel: 5, rarity: .common,   weight: 100),
        UpgradeData(id: .quickShot,    name: "Quick Shot",    icon: "⚡",  description: "+20% Attack Speed",        maxLevel: 5, rarity: .common,   weight: 100),
        UpgradeData(id: .longRange,    name: "Long Range",    icon: "🎯",  description: "+25% Arrow Range",         maxLevel: 4, rarity: .common,   weight: 100),
        UpgradeData(id: .multiShot,    name: "Multi Shot",    icon: "🏹🏹", description: "+1 Arrow simultaneously",  maxLevel: 3, rarity: .uncommon, weight: 50),
        UpgradeData(id: .pierce,       name: "Pierce",        icon: "➡️",  description: "Arrow pierces +1 enemy",   maxLevel: 3, rarity: .uncommon, weight: 50),
        UpgradeData(id: .explosiveTip, name: "Explosive Tip", icon: "💥",  description: "AoE explosion on hit (r=60)", maxLevel: 3, rarity: .uncommon, weight: 50),
        UpgradeData(id: .poisonArrow,  name: "Poison Arrow",  icon: "☠️",  description: "5 dmg/sec for 4s",         maxLevel: 3, rarity: .uncommon, weight: 50),
        UpgradeData(id: .forkShot,     name: "Fork Shot",     icon: "🍴",  description: "Arrow splits into 2 on hit", maxLevel: 2, rarity: .uncommon, weight: 50),
        UpgradeData(id: .boomerang,    name: "Boomerang",     icon: "🪃",  description: "Arrow returns after range", maxLevel: 2, rarity: .uncommon, weight: 50),
        UpgradeData(id: .criticalEye,  name: "Critical Eye",  icon: "👁️",  description: "+10% Crit Chance",         maxLevel: 5, rarity: .common,   weight: 100),

        // Defense
        UpgradeData(id: .barkArmor,    name: "Bark Armor",    icon: "🌳",  description: "+25 Max HP",               maxLevel: 5, rarity: .common,   weight: 100),
        UpgradeData(id: .forestShield, name: "Forest Shield", icon: "🛡️",  description: "-15% Damage Taken",        maxLevel: 3, rarity: .uncommon, weight: 50),
        UpgradeData(id: .regeneration, name: "Regeneration",  icon: "💚",  description: "+3 HP/sec",                maxLevel: 3, rarity: .uncommon, weight: 50),
        UpgradeData(id: .thornAura,    name: "Thorn Aura",    icon: "🌿",  description: "5 dmg/sec to nearby enemies", maxLevel: 2, rarity: .uncommon, weight: 50),
        UpgradeData(id: .secondWind,   name: "Second Wind",   icon: "💨",  description: "Survive one lethal hit at 1HP", maxLevel: 1, rarity: .rare, weight: 20),

        // Utility
        UpgradeData(id: .swiftBoots,   name: "Swift Boots",   icon: "👟",  description: "+15% Move Speed",         maxLevel: 4, rarity: .common,   weight: 100),
        UpgradeData(id: .coinMagnet,   name: "Coin Magnet",   icon: "🧲",  description: "+60% Pickup Radius",      maxLevel: 3, rarity: .common,   weight: 100),
        UpgradeData(id: .blink,        name: "Blink",         icon: "🌀",  description: "Double-tap to Dash (4s CD)", maxLevel: 1, rarity: .rare, weight: 20),
    ]

    static func find(_ id: UpgradeID) -> UpgradeData? {
        return all.first { $0.id == id }
    }
}
