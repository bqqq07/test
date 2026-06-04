import SpriteKit

enum PlayerState {
    case idle, moving, attacking, hurt, dead
}

final class Player: SKNode {
    let sprite: SKSpriteNode
    private(set) var state: PlayerState = .idle

    var stats: PlayerStats { didSet { updateAura() } }
    private var auraNode: SKNode?

    private var blinkCooldown: TimeInterval = 0
    private let blinkDuration: TimeInterval = 4.0
    private var slowMultiplier: CGFloat = 1.0
    private var slowTimer: TimeInterval = 0

    init(stats: PlayerStats) {
        self.stats = stats
        let playerSize = CGSize(width: 32, height: 32)
        sprite = SKSpriteNode(texture: .placeholder(color: UIColor(red: 0.2, green: 0.6, blue: 1.0, alpha: 1), size: playerSize), size: playerSize)
        // Archer icon
        let icon = SKLabelNode(text: "🏹")
        icon.fontSize = 18
        icon.verticalAlignmentMode = .center
        icon.horizontalAlignmentMode = .center
        icon.zPosition = 1
        sprite.addChild(icon)
        super.init()

        addChild(sprite)
        zPosition = Constants.ZPositions.entities
        setupPhysics()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupPhysics() {
        physicsBody = SKPhysicsBody(circleOfRadius: 14)
        physicsBody?.categoryBitMask    = PhysicsCategory.player
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy | PhysicsCategory.coin
        physicsBody?.collisionBitMask   = PhysicsCategory.none
        physicsBody?.affectedByGravity  = false
        physicsBody?.isDynamic          = true
    }

    // MARK: - Update

    func update(delta: TimeInterval, joystickVector: CGVector) {
        guard state != .dead else { return }

        if slowTimer > 0 {
            slowTimer -= delta
            if slowTimer <= 0 { slowMultiplier = 1.0 }
        }

        if blinkCooldown > 0 { blinkCooldown -= delta }

        let speed = stats.moveSpeed * CGFloat(delta) * slowMultiplier
        let dx = joystickVector.dx * speed
        let dy = joystickVector.dy * speed

        let moving = (abs(dx) + abs(dy)) > 0.01
        position.x += dx
        position.y += dy

        clampToMap()

        if moving {
            setState(.moving)
            sprite.xScale = dx < 0 ? -abs(sprite.xScale) : abs(sprite.xScale)
        } else {
            setState(.idle)
        }

        // Regen
        if stats.regenPerSec > 0 {
            stats.applyHealing(stats.regenPerSec * Float(delta))
        }
    }

    private func clampToMap() {
        let half = Constants.mapSize
        position.x = position.x.clamped(to: 0...half.width)
        position.y = position.y.clamped(to: 0...half.height)
    }

    func setState(_ newState: PlayerState) {
        guard state != newState, state != .dead else { return }
        state = newState
        updateAnimation()
    }

    private func updateAnimation() {
        sprite.removeAction(forKey: "anim")
        switch state {
        case .idle:
            let pulse = SKAction.sequence([.scale(to: 1.05, duration: 0.5), .scale(to: 1.0, duration: 0.5)])
            sprite.run(.repeatForever(pulse), withKey: "anim")
        case .moving:
            break
        case .attacking:
            let flash = SKAction.sequence([.scale(to: 1.2, duration: 0.05), .scale(to: 1.0, duration: 0.05)])
            sprite.run(flash, withKey: "anim")
        case .hurt:
            sprite.run(.sequence([
                .colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
                .colorize(with: .white, colorBlendFactor: 0, duration: 0.1),
                .run { [weak self] in self?.setState(.idle) }
            ]), withKey: "anim")
        case .dead:
            sprite.run(.sequence([
                .scale(to: 1.5, duration: 0.1),
                .fadeOut(withDuration: 0.3)
            ]), withKey: "anim")
        }
    }

    // MARK: - Combat

    func receiveDamage(_ amount: Float) -> Bool {
        guard state != .dead else { return false }
        hurtFlash()
        let died = stats.applyDamage(amount)
        if died {
            setState(.dead)
        } else {
            setState(.hurt)
        }
        return died
    }

    private func hurtFlash() {
        let flash = SKAction.sequence([
            .colorize(with: .red, colorBlendFactor: 0.8, duration: 0.05),
            .colorize(with: .white, colorBlendFactor: 0, duration: 0.1)
        ])
        sprite.run(.repeat(flash, count: 2))
    }

    func applySlow(multiplier: CGFloat, duration: Float) {
        slowMultiplier = 1.0 - (1.0 - multiplier) * 0.3
        slowTimer = TimeInterval(duration)
    }

    // MARK: - Blink Dash

    func tryBlink(direction: CGVector) -> Bool {
        guard stats.hasBlink, blinkCooldown <= 0 else { return false }
        blinkCooldown = blinkDuration
        let dashDist: CGFloat = 120
        let target = CGPoint(
            x: position.x + direction.dx * dashDist,
            y: position.y + direction.dy * dashDist
        )
        let dash = SKAction.sequence([
            .fadeAlpha(to: 0.3, duration: 0.05),
            .move(to: target, duration: 0.15),
            .fadeAlpha(to: 1.0, duration: 0.05)
        ])
        run(dash)
        return true
    }

    // MARK: - Thorn Aura

    private func updateAura() {
        auraNode?.removeFromParent()
        guard stats.thornAuraDamage > 0 else { return }
        let aura = SKShapeNode(circleOfRadius: stats.thornAuraRadius)
        aura.fillColor = SKColor(hex: "#27AE60").withAlphaComponent(0.15)
        aura.strokeColor = SKColor(hex: "#27AE60").withAlphaComponent(0.4)
        aura.zPosition = -0.5

        let pulse = SKAction.sequence([
            .fadeAlpha(to: 0.3, duration: 0.8),
            .fadeAlpha(to: 1.0, duration: 0.8)
        ])
        aura.run(.repeatForever(pulse))
        addChild(aura)

        let auraBody  = SKPhysicsBody(circleOfRadius: stats.thornAuraRadius)
        auraBody.categoryBitMask    = PhysicsCategory.playerAura
        auraBody.contactTestBitMask = PhysicsCategory.enemy
        auraBody.collisionBitMask   = PhysicsCategory.none
        auraBody.affectedByGravity  = false
        aura.physicsBody = auraBody
        auraNode = aura
    }
}
