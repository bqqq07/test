import SpriteKit

final class Bat: Enemy {
    private var sinOffset: CGFloat = 0
    private let sinAmplitude: CGFloat = 30
    private let sinFrequency: CGFloat = 3.0

    init() { super.init(type: .bat) }
    required init?(coder: NSCoder) { fatalError() }

    override func update(delta: TimeInterval, playerPosition: CGPoint) {
        guard isAlive else { return }
        sinOffset += CGFloat(delta) * sinFrequency

        let diff   = CGPoint(x: playerPosition.x - position.x, y: playerPosition.y - position.y)
        let dist   = hypot(diff.x, diff.y)
        guard dist > 2 else { return }

        let forward   = CGPoint(x: diff.x / dist, y: diff.y / dist)
        let perp      = CGPoint(x: -forward.y, y: forward.x)
        let sideShift = sin(sinOffset) * sinAmplitude * CGFloat(delta)
        let speed     = CGFloat(data.moveSpeed) * CGFloat(delta)

        position.x += forward.x * speed + perp.x * sideShift
        position.y += forward.y * speed + perp.y * sideShift
        face(point: playerPosition)
    }
}
