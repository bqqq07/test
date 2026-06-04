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

    // Placeholder colors per enemy type
    static func placeholderColor(for type: EnemyType) -> UIColor {
        switch type {
        case .wolf:         return UIColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1)  // brown-gray
        case .bat:          return UIColor(red: 0.3, green: 0.1, blue: 0.4, alpha: 1)  // dark purple
        case .boar:         return UIColor(red: 0.6, green: 0.3, blue: 0.1, alpha: 1)  // orange-brown
        case .vineCreature: return UIColor(red: 0.1, green: 0.5, blue: 0.1, alpha: 1)  // green
        case .troll:        return UIColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 1)  // dark green
        case .ancientGolem: return UIColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1)  // gray
        }
    }

    init(type: EnemyType) {
        self.type = type
        self.data = EnemyData.data(for: type)
        self.maxHP = data.baseHP
        self.currentHP = data.baseHP

        let color = Enemy.placeholderColor(for: type)
        sprite = SKSpriteNode(texture: .placeholder(color: color, size: data.size), size: data.size)
        super.init()

        // Label showing enemy type initial
        let label = SKLabelNode(text: String(type.rawValue.prefix(1)).uppercased())
        label.fontSize = data.size.height * 0.5
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        sprite.addChild(label)

        addChild(sprite)
        zPosition = Constants.ZPositions.entities
        setupPhysics()
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
        let shrink = SKAction.sequence([
            .scale(to: 1.3, duration: 0.05),
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ])
        sprite.run(shrink) { [weak self] in self?.removeFromParent() }
    }

    func reset() {
        isAlive = true
        currentHP = maxHP * waveHPMultiplier
        sprite.alpha = 1
        sprite.xScale = 1
        sprite.yScale = 1
        sprite.removeAllActions()
        setupPhysics()
    }
}
