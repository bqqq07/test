import SpriteKit

final class JoystickNode: SKNode {
    private let base: SKSpriteNode
    private let thumb: SKSpriteNode
    private(set) var velocity: CGVector = .zero

    let radius: CGFloat = 60
    private var touchID: UITouch?

    override init() {
        base = SKSpriteNode(imageNamed: "joystick_base")
        base.size = CGSize(width: 120, height: 120)
        base.alpha = 0.5

        thumb = SKSpriteNode(imageNamed: "joystick_thumb")
        thumb.size = CGSize(width: 56, height: 56)
        thumb.alpha = 0.7

        super.init()
        addChild(base)
        addChild(thumb)
        isUserInteractionEnabled = true
    }

    required init?(coder: NSCoder) { fatalError() }

    func handleTouchBegan(_ touch: UITouch, in node: SKNode) {
        guard touchID == nil else { return }
        touchID = touch
        updateThumb(touch: touch, in: node)
    }

    func handleTouchMoved(_ touch: UITouch, in node: SKNode) {
        guard touch === touchID else { return }
        updateThumb(touch: touch, in: node)
    }

    func handleTouchEnded(_ touch: UITouch) {
        guard touch === touchID else { return }
        touchID = nil
        reset()
    }

    private func updateThumb(touch: UITouch, in node: SKNode) {
        let touchPt = touch.location(in: node)
        let offset   = CGPoint(x: touchPt.x - position.x, y: touchPt.y - position.y)
        let distance = hypot(offset.x, offset.y)
        let clamped  = min(distance, radius)
        let angle    = atan2(offset.y, offset.x)

        thumb.position = CGPoint(x: cos(angle) * clamped, y: sin(angle) * clamped)
        velocity = CGVector(
            dx: (clamped / radius) * cos(angle),
            dy: (clamped / radius) * sin(angle)
        )
    }

    func reset() {
        velocity = .zero
        let snap = SKAction.move(to: .zero, duration: 0.08)
        snap.timingMode = .easeOut
        thumb.run(snap)
    }
}
