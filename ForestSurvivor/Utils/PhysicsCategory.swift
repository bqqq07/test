import Foundation

struct PhysicsCategory {
    static let none:        UInt32 = 0
    static let player:      UInt32 = 0b00001   // 1
    static let enemy:       UInt32 = 0b00010   // 2
    static let arrow:       UInt32 = 0b00100   // 4
    static let coin:        UInt32 = 0b01000   // 8
    static let playerAura:  UInt32 = 0b10000   // 16
}

// Collision Matrix:
// arrow  ↔ enemy  ✅
// player ↔ enemy  ✅ (contact = damage)
// player ↔ coin   ✅ (collect)
// arrow  ↔ player ❌
// arrow  ↔ arrow  ❌
// enemy  ↔ enemy  ❌ (pass through)
