import SpriteKit

final class HPBarNode: SKNode {
    private let background: SKSpriteNode
    private let fill: SKSpriteNode
    private let width: CGFloat
    private let height: CGFloat = 12

    init(width: CGFloat = 160) {
        self.width = width
        background = SKSpriteNode(color: SKColor(hex: "#1C1C2E"), size: CGSize(width: width, height: 12))
        fill       = SKSpriteNode(color: SKColor(hex: "#2ECC71"), size: CGSize(width: width, height: 12))
        super.init()
        background.anchorPoint = CGPoint(x: 0, y: 0.5)
        fill.anchorPoint       = CGPoint(x: 0, y: 0.5)
        addChild(background)
        addChild(fill)
    }

    required init?(coder: NSCoder) { fatalError() }

    func update(current: Float, max: Float) {
        let pct = CGFloat(max > 0 ? current / max : 0).clamped(to: 0...1)
        let action = SKAction.scaleX(to: pct, duration: 0.1)
        fill.run(action)

        if pct > 0.5 {
            fill.color = SKColor(hex: "#2ECC71")
        } else if pct > 0.25 {
            fill.color = SKColor(hex: "#F1C40F")
        } else {
            fill.color = SKColor(hex: "#E74C3C")
        }
    }
}

extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
