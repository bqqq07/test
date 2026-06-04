import SpriteKit

final class UpgradeCardNode: SKNode {
    let upgrade: UpgradeData
    private let background: SKSpriteNode
    var onSelected: (() -> Void)?

    init(upgrade: UpgradeData) {
        self.upgrade = upgrade
        background = SKSpriteNode(imageNamed: "upgrade_card_bg")
        background.size = CGSize(width: 100, height: 140)
        background.color = SKColor(hex: "#252540")
        background.colorBlendFactor = 0.8
        super.init()
        isUserInteractionEnabled = true
        setupUI()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupUI() {
        addChild(background)

        let icon = SKLabelNode(text: upgrade.icon)
        icon.fontSize = 28
        icon.position = CGPoint(x: 0, y: 30)
        icon.verticalAlignmentMode = .center
        addChild(icon)

        let name = SKLabelNode(fontNamed: Constants.Fonts.primary)
        name.text = upgrade.name
        name.fontSize = 6
        name.fontColor = SKColor(hex: "#F0EDE8")
        name.position = CGPoint(x: 0, y: 5)
        name.preferredMaxLayoutWidth = 90
        name.numberOfLines = 2
        name.horizontalAlignmentMode = .center
        addChild(name)

        let desc = SKLabelNode(fontNamed: Constants.Fonts.body)
        desc.text = upgrade.description
        desc.fontSize = 10
        desc.fontColor = SKColor(hex: "#B8B5B0")
        desc.position = CGPoint(x: 0, y: -30)
        desc.preferredMaxLayoutWidth = 90
        desc.numberOfLines = 3
        desc.horizontalAlignmentMode = .center
        addChild(desc)

        let rarityColor: SKColor = {
            switch upgrade.rarity {
            case .common:   return SKColor(hex: "#B8B5B0")
            case .uncommon: return SKColor(hex: "#3498DB")
            case .rare:     return SKColor(hex: "#F4D03F")
            }
        }()
        background.color = rarityColor
        background.colorBlendFactor = 0.15
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        let scale = SKAction.sequence([
            .scale(to: 0.95, duration: 0.05),
            .scale(to: 1.05, duration: 0.05)
        ])
        run(scale)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        onSelected?()
    }
}
