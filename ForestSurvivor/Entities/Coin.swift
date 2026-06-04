import SpriteKit

final class Coin: SKSpriteNode {
    var value: Int = 1
    private var lifetime: TimeInterval = 8.0
    private var elapsed: TimeInterval = 0
    private var isBeingCollected = false

    init(value: Int = 1) {
        self.value = value
        let coinSize = CGSize(width: 14, height: 14)
        let texture = SKTexture.circle(color: UIColor(red: 0.95, green: 0.82, blue: 0.1, alpha: 1), radius: 7)
        super.init(texture: texture, color: .clear, size: coinSize)
        zPosition = Constants.ZPositions.entities

        physicsBody = SKPhysicsBody(circleOfRadius: 8)
        physicsBody?.categoryBitMask    = PhysicsCategory.coin
        physicsBody?.contactTestBitMask = PhysicsCategory.player
        physicsBody?.collisionBitMask   = PhysicsCategory.none
        physicsBody?.affectedByGravity  = false
        physicsBody?.isDynamic          = false

        startSpinAnimation()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func startSpinAnimation() {
        let spin = SKAction.repeatForever(.sequence([
            .scaleX(to: 0.2, duration: 0.2),
            .scaleX(to: 1.0, duration: 0.2)
        ]))
        run(spin, withKey: "spin")
    }

    func update(delta: TimeInterval) {
        guard !isBeingCollected else { return }
        elapsed += delta

        let remaining = lifetime - elapsed
        if remaining <= 2.0 {
            let blink = SKAction.sequence([
                .fadeAlpha(to: 0.2, duration: 0.2),
                .fadeAlpha(to: 1.0, duration: 0.2)
            ])
            if action(forKey: "blink") == nil {
                run(.repeatForever(blink), withKey: "blink")
            }
        }

        if elapsed >= lifetime { removeFromParent() }
    }

    func attract(to target: CGPoint, completion: @escaping () -> Void) {
        guard !isBeingCollected else { return }
        isBeingCollected = true
        physicsBody = nil
        removeAction(forKey: "blink")
        let attract = SKAction.move(to: target, duration: 0.25)
        attract.timingMode = .easeIn
        run(.sequence([attract, .removeFromParent()])) {
            completion()
        }
    }
}
