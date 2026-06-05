import SpriteKit

final class UpgradeScene: SKScene {
    private let upgrades: [UpgradeData]
    private let onPicked: (UpgradeData) -> Void

    init(size: CGSize, upgrades: [UpgradeData], onPicked: @escaping (UpgradeData) -> Void) {
        self.upgrades = upgrades
        self.onPicked = onPicked
        super.init(size: size)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        setupBackground()
        setupCards()
        setupHeader()
    }

    private func setupBackground() {
        backgroundColor = .clear
        let blur = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.7), size: size)
        blur.position = CGPoint(x: size.width / 2, y: size.height / 2)
        blur.zPosition = -1
        addChild(blur)
    }

    private func setupHeader() {
        let title = SKLabelNode(fontNamed: Constants.Fonts.primary)
        title.text = "⭐ LEVEL UP! ⭐"
        title.fontSize = 16
        title.fontColor = SKColor(hex: "#F4D03F")
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.72)
        addChild(title)

        let sub = SKLabelNode(fontNamed: Constants.Fonts.body)
        sub.text = "Choose Your Power"
        sub.fontSize = 20
        sub.fontColor = SKColor(hex: "#B8B5B0")
        sub.position = CGPoint(x: size.width / 2, y: size.height * 0.66)
        addChild(sub)
    }

    private func setupCards() {
        let cardWidth: CGFloat = 100
        let spacing: CGFloat = 20
        let totalWidth = CGFloat(upgrades.count) * cardWidth + CGFloat(upgrades.count - 1) * spacing
        let startX = size.width / 2 - totalWidth / 2 + cardWidth / 2

        for (i, upgrade) in upgrades.enumerated() {
            let card = UpgradeCardNode(upgrade: upgrade)
            card.position = CGPoint(x: startX + CGFloat(i) * (cardWidth + spacing),
                                    y: size.height * 0.48)

            // Animate in from top
            let startY = card.position.y + 100
            card.position.y = startY
            let drop = SKAction.sequence([
                .wait(forDuration: Double(i) * 0.1),
                .move(to: CGPoint(x: card.position.x, y: size.height * 0.48),
                      duration: 0.3)
            ])
            drop.timingMode = .easeOut
            card.run(drop)

            card.onSelected = { [weak self] in
                self?.pickUpgrade(upgrade)
            }
            addChild(card)
        }
    }

    private func pickUpgrade(_ upgrade: UpgradeData) {
        // Prevent double-tap
        isUserInteractionEnabled = false

        let flash = SKAction.sequence([
            .fadeAlpha(to: 0.5, duration: 0.1),
            .fadeAlpha(to: 1.0, duration: 0.1),
            .run { [weak self] in
                guard let self = self else { return }
                self.onPicked(upgrade)
                // Return to previous GameScene if it exists in the view stack
                if let view = self.view {
                    let gameScene = GameScene(size: self.size)
                    gameScene.scaleMode = self.scaleMode
                    view.presentScene(gameScene, transition: .crossFade(withDuration: 0.2))
                }
            }
        ])
        run(flash)
    }
}
