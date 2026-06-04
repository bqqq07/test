import SpriteKit

final class BossHPBarNode: SKNode {
    private let background: SKSpriteNode
    private let fill: SKSpriteNode
    private let label: SKLabelNode
    private let width: CGFloat = 260

    override init() {
        background = SKSpriteNode(color: .black, size: CGSize(width: 264, height: 20))
        fill       = SKSpriteNode(color: SKColor(hex: "#8E44AD"), size: CGSize(width: 260, height: 16))
        label      = SKLabelNode(fontNamed: Constants.Fonts.primary)
        super.init()

        background.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        fill.anchorPoint       = CGPoint(x: 0, y: 0.5)
        fill.position          = CGPoint(x: -width / 2, y: 0)

        label.fontSize   = 8
        label.fontColor  = SKColor(hex: "#F0EDE8")
        label.position   = CGPoint(x: 0, y: 14)
        label.text       = "ANCIENT GOLEM"
        label.verticalAlignmentMode = .center

        addChild(background)
        addChild(fill)
        addChild(label)
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(current: Float, max: Float) {
        let pct = CGFloat(max > 0 ? current / max : 0).clamped(to: 0...1)
        fill.xScale = pct
    }
}
