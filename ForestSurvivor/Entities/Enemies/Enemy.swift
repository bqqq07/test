import SpriteKit

class Enemy: SKNode {
    let type: EnemyType
    var data: EnemyData
    var currentHP: Float
    var maxHP: Float
    var isAlive: Bool = true

    private(set) var sprite: SKSpriteNode
    var contactDamagePerSec: Float { data.damagePerSec }

    var waveHPMultiplier: Float = 1.0

    init(type: EnemyType) {
        self.type = type
        self.data = EnemyData.data(for: type)
        self.maxHP = data.baseHP
        self.currentHP = data.baseHP

        sprite = SKSpriteNode(color: .red, size: data.size)
        sprite.texture = SKTexture(imageNamed: "\(type.rawValue)_walk_00")
        super.init()

        addChild(sprite)
        zPosition = Constants.ZPositions.entities
        setupPhysics()
        startWalkAnimation()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: data.size.width * 0.7,
                                                        height: data.size.height * 0.7))
        physicsBody?.categoryBitMask    = PhysicsCategory.enemy
        physicsBody?.contactTestBitMask = PhysicsCategory.arrow | PhysicsCategory.player | PhysicsCategory.playerAura
        physicsBody?.collisionBitMask   = PhysicsCategory.none
        physicsBody?.affectedByGravity  = false
        physicsBody?.isDynamic          = true
    }

    private func startWalkAnimation() {
        let frames = (0..<6).map { SKTexture(imageNamed: "\(type.rawValue)_walk_0\($0)") }
        let anim = SKAction.repeatForever(.animate(with: frames, timePerFrame: 0.1))
        sprite.run(anim, withKey: "walk")
    }

    // MARK: - Update

    func update(delta: TimeInterval, playerPosition: CGPoint) {
        guard isAlive else { return }
        moveToward(target: playerPosition, delta: delta)
        face(point: playerPosition)
    }

    func moveToward(target: CGPoint, delta: TimeInterval) {
        let diff = CGPoint(x: target.x - position.x, y: target.y - position.y)
        let dist = hypot(diff.x, diff.y)
        guard dist > 2 else { return }
        let norm = CGPoint(x: diff.x / dist, y: diff.y / dist)
        let speed = CGFloat(data.moveSpeed) * CGFloat(delta)
        position.x += norm.x * speed
        position.y += norm.y * speed
    }

    func face(point: CGPoint) {
        sprite.xScale = point.x < position.x ? -abs(sprite.xScale) : abs(sprite.xScale)
    }

    // MARK: - Damage

    func takeDamage(_ amount: Float) -> Bool {
        guard isAlive else { return false }
        let effective = max(0, amount - data.armor)
        currentHP -= effective
        hitFlash()
        if currentHP <= 0 {
            die()
            return true
        }
        return false
    }

    private func hitFlash() {
        let flash = SKAction.sequence([
            .colorize(with: .white, colorBlendFactor: 0.9, duration: 0.04),
            .colorize(with: .white, colorBlendFactor: 0.0, duration: 0.06)
        ])
        sprite.run(flash)
    }

    func die() {
        isAlive = false
        physicsBody = nil
        sprite.removeAllActions()

        let frames = (0..<4).map { SKTexture(imageNamed: "\(type.rawValue)_death_0\($0)") }
        let death = SKAction.animate(with: frames, timePerFrame: 0.1)
        sprite.run(.sequence([death, .removeFromParent()])) { [weak self] in
            self?.removeFromParent()
        }
    }

    func reset() {
        isAlive = true
        currentHP = maxHP * waveHPMultiplier
        sprite.alpha = 1
        sprite.removeAllActions()
        physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: data.size.width * 0.7,
                                                        height: data.size.height * 0.7))
        setupPhysics()
        startWalkAnimation()
    }
}
