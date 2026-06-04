import SpriteKit

final class Coin: SKSpriteNode {
    var value: Int = 1
    private var lifetime: TimeInterval = 8.0
    private var elapsed: TimeInterval = 0
    private var isBeingCollected = false

    init(value: Int = 1) {
        self.value = value
        let texture = SKTexture(imageNamed: "coin_00")
        super.init(texture: texture, color: .clear, size: CGSize(width: 16, height: 16))
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
        let frames = (0..<4).map { SKTexture(imageNamed: "coin_0\($0)") }
        let spin = SKAction.repeatForever(.animate(with: frames, timePerFrame: 0.1))
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
