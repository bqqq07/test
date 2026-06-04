import CoreGraphics
import Foundation

enum EnemyType: String, CaseIterable {
    case wolf
    case bat
    case boar
    case vineCreature
    case troll
    case ancientGolem
}

struct EnemyData {
    let type: EnemyType
    let baseHP: Float
    let armor: Float
    let moveSpeed: CGFloat
    let damagePerSec: Float
    let coins: Int
    let xp: Int
    let spawnAfterSeconds: TimeInterval
    let size: CGSize

    static let wolf = EnemyData(
        type: .wolf, baseHP: 40, armor: 0, moveSpeed: 130,
        damagePerSec: 8, coins: 3, xp: 5,
        spawnAfterSeconds: 0,
        size: CGSize(width: 32, height: 32)
    )
    static let bat = EnemyData(
        type: .bat, baseHP: 25, armor: 0, moveSpeed: 220,
        damagePerSec: 5, coins: 4, xp: 8,
        spawnAfterSeconds: 120,
        size: CGSize(width: 24, height: 24)
    )
    static let boar = EnemyData(
        type: .boar, baseHP: 90, armor: 5, moveSpeed: 70,
        damagePerSec: 18, coins: 8, xp: 12,
        spawnAfterSeconds: 90,
        size: CGSize(width: 36, height: 36)
    )
    static let vineCreature = EnemyData(
        type: .vineCreature, baseHP: 60, armor: 0, moveSpeed: 90,
        damagePerSec: 6, coins: 6, xp: 10,
        spawnAfterSeconds: 240,
        size: CGSize(width: 32, height: 40)
    )
    static let troll = EnemyData(
        type: .troll, baseHP: 250, armor: 15, moveSpeed: 40,
        damagePerSec: 35, coins: 20, xp: 30,
        spawnAfterSeconds: 180,
        size: CGSize(width: 48, height: 56)
    )
    static let ancientGolem = EnemyData(
        type: .ancientGolem, baseHP: 2500, armor: 30, moveSpeed: 55,
        damagePerSec: 50, coins: 150, xp: 200,
        spawnAfterSeconds: 300,
        size: CGSize(width: 80, height: 96)
    )

    static func data(for type: EnemyType) -> EnemyData {
        switch type {
        case .wolf:         return .wolf
        case .bat:          return .bat
        case .boar:         return .boar
        case .vineCreature: return .vineCreature
        case .troll:        return .troll
        case .ancientGolem: return .ancientGolem
        }
    }
}
