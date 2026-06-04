import SpriteKit

final class Arrow: SKSpriteNode {
    var damage: Float = 20
    var speed: CGFloat = 500
    var direction: CGVector = .zero
    var range: CGFloat = 280
    var distanceTraveled: CGFloat = 0
    var startPosition: CGPoint = .zero

    var pierceCount: Int = 1
    var hitEnemies: Set<ObjectIdentifier> = []

    var hasPoison: Bool = false
    var poisonDamage: Float = 0
    var poisonDuration: Float = 0

    var hasExplosive: Bool = false
    var explosiveRadius: CGFloat = 60

    var hasFork: Bool = false
    var hasBoomerang: Bool = false
    private var returning: Bool = false

    init() {
        let texture = SKTexture(imageNamed: "arrow")
        super.init(texture: texture, color: .clear, size: CGSize(width: 20, height: 8))
        zPosition = Constants.ZPositions.entities

        physicsBody = SKPhysicsBody(rectangleOf: size)
        physicsBody?.categoryBitMask    = PhysicsCategory.arrow
        physicsBody?.contactTestBitMask = PhysicsCategory.enemy
        physicsBody?.collisionBitMask   = PhysicsCategory.none
        physicsBody?.affectedByGravity  = false
        physicsBody?.isDynamic          = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func configure(from stats: PlayerStats) {
        damage          = stats.attackDamage
        speed           = stats.arrowSpeed
        range           = stats.arrowRange
        pierceCount     = stats.pierceCount
        hasPoison       = stats.poisonDamage > 0
        poisonDamage    = stats.poisonDamage
        poisonDuration  = stats.poisonDuration
        hasExplosive    = stats.hasExplosiveTip
        explosiveRadius = stats.explosiveRadius
        hasFork         = stats.hasForkShot
        hasBoomerang    = stats.hasBoomerang
    }

    func update(delta: TimeInterval) {
        guard let scene = scene else { return }
        let ds = speed * CGFloat(delta)
        let move = CGVector(dx: direction.dx * ds, dy: direction.dy * ds)

        if hasBoomerang && distanceTraveled >= range && !returning {
            returning = true
            direction = CGVector(dx: -direction.dx, dy: -direction.dy)
        }

        position.x += move.dx
        position.y += move.dy
        distanceTraveled += ds

        zRotation = atan2(direction.dy, direction.dx)

        let shouldRemove = !hasBoomerang
            ? distanceTraveled >= range
            : returning && distanceTraveled >= range * 2

        if shouldRemove { removeFromParent() }

        let half = scene.size
        if abs(position.x) > half.width || abs(position.y) > half.height {
            removeFromParent()
        }
    }
}
