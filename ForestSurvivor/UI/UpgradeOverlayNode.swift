import SpriteKit

final class UpgradeOverlayNode: SKNode {
    private let onPicked: (UpgradeData) -> Void
    private var didPick = false

    init(size: CGSize, upgrades: [UpgradeData], onPicked: @escaping (UpgradeData) -> Void) {
        self.onPicked = onPicked
        super.init()

        // Dim background
        let dim = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.75), size: size)
        dim.zPosition = -1
        addChild(dim)

        // Title
        let title = SKLabelNode(fontNamed: Constants.Fonts.primary)
        title.text = "⭐ LEVEL UP! ⭐"
        title.fontSize = 14
        title.fontColor = SKColor(hex: "#F4D03F")
        title.position = CGPoint(x: 0, y: size.height * 0.28)
        addChild(title)

        let sub = SKLabelNode(fontNamed: Constants.Fonts.body)
        sub.text = "Choose Your Power"
        sub.fontSize = 20
        sub.fontColor = SKColor(hex: "#B8B5B0")
        sub.position = CGPoint(x: 0, y: size.height * 0.22)
        addChild(sub)

        // Cards
        let cardWidth: CGFloat = 100
        let spacing: CGFloat = 20
        let total = CGFloat(upgrades.count) * cardWidth + CGFloat(upgrades.count - 1) * spacing
        let startX = -total / 2 + cardWidth / 2

        for (i, upgrade) in upgrades.enumerated() {
            let card = UpgradeCardNode(upgrade: upgrade)
            card.position = CGPoint(x: startX + CGFloat(i) * (cardWidth + spacing), y: 0)

            // Drop in from top
            let finalY = card.position.y
            card.position.y = finalY + 120
            let drop = SKAction.sequence([
                .wait(forDuration: Double(i) * 0.08),
                .move(to: CGPoint(x: card.position.x, y: finalY), duration: 0.25)
            ])
            drop.timingMode = .easeOut
            card.run(drop)

            card.onSelected = { [weak self] in
                self?.select(upgrade)
            }
            addChild(card)
        }
    }

    required init?(coder: NSCoder) { fatalError() }

    private func select(_ upgrade: UpgradeData) {
        guard !didPick else { return }
        didPick = true

        run(.sequence([
            .fadeOut(withDuration: 0.15),
            .removeFromParent(),
            .run { [weak self] in self?.onPicked(upgrade) }
        ]))
    }
}
