import SpriteKit

final class Boar: Enemy {
    private var dodgeAngle: CGFloat = 0
    private var dodgeTimer: TimeInterval = 0
    private let dodgeInterval: TimeInterval = 2.0

    init() { super.init(type: .boar) }
    required init?(coder: NSCoder) { fatalError() }

    override func update(delta: TimeInterval, playerPosition: CGPoint) {
        guard isAlive else { return }
        dodgeTimer += delta
        if dodgeTimer >= dodgeInterval {
            dodgeTimer = 0
            dodgeAngle = CGFloat.random(in: -0.5...0.5)
        }

        let diff   = CGPoint(x: playerPosition.x - position.x, y: playerPosition.y - position.y)
        let dist   = hypot(diff.x, diff.y)
        guard dist > 2 else { return }

        let baseAngle = atan2(diff.y, diff.x) + dodgeAngle
        let speed     = CGFloat(data.moveSpeed) * CGFloat(delta)
        position.x   += cos(baseAngle) * speed
        position.y   += sin(baseAngle) * speed
        face(point: playerPosition)
    }
}
