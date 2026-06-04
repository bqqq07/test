import SpriteKit

final class HUDNode: SKNode {
    private let hpBar: HPBarNode
    private let timerLabel: SKLabelNode
    private let coinLabel: SKLabelNode
    private let killsLabel: SKLabelNode
    private(set) var bossHPBar: BossHPBarNode?

    private let screenSize: CGSize

    init(screenSize: CGSize) {
        self.screenSize = screenSize
        hpBar       = HPBarNode(width: 160)
        timerLabel  = SKLabelNode(fontNamed: Constants.Fonts.primary)
        coinLabel   = SKLabelNode(fontNamed: Constants.Fonts.primary)
        killsLabel  = SKLabelNode(fontNamed: Constants.Fonts.primary)
        super.init()
        zPosition = Constants.ZPositions.hud
        setupLayout()
    }

    required init?(coder: NSCoder) { fatalError() }

    private func setupLayout() {
        let top    =  screenSize.height / 2 - 30
        let left   = -screenSize.width  / 2 + 20
        let right  =  screenSize.width  / 2 - 20
        let bottom = -screenSize.height / 2 + 20

        // HP Bar — top left
        hpBar.position = CGPoint(x: left, y: top)
        addChild(hpBar)

        // Timer — top center
        timerLabel.fontSize = 14
        timerLabel.fontColor = SKColor(hex: "#F0EDE8")
        timerLabel.text = "0:00"
        timerLabel.position = CGPoint(x: 0, y: top)
        timerLabel.horizontalAlignmentMode = .center
        addChild(timerLabel)

        // Coins — top right
        coinLabel.fontSize = 12
        coinLabel.fontColor = SKColor(hex: "#F4D03F")
        coinLabel.text = "💰 0"
        coinLabel.position = CGPoint(x: right, y: top)
        coinLabel.horizontalAlignmentMode = .right
        addChild(coinLabel)

        // Kills — bottom right
        killsLabel.fontSize = 10
        killsLabel.fontColor = SKColor(hex: "#B8B5B0")
        killsLabel.text = "KILLS: 0"
        killsLabel.position = CGPoint(x: right, y: bottom)
        killsLabel.horizontalAlignmentMode = .right
        addChild(killsLabel)
    }

    func update(time: TimeInterval, coins: Int, hp: Float, maxHP: Float, kills: Int) {
        timerLabel.text = time.mmss
        coinLabel.text  = "💰 \(coins)"
        killsLabel.text = "KILLS: \(kills)"
        hpBar.update(current: hp, max: maxHP)
    }

    func showBossHPBar(bossName: String) {
        hideBossHPBar()
        let bar = BossHPBarNode()
        bar.position = CGPoint(x: 0, y: screenSize.height / 2 - 60)
        addChild(bar)
        bossHPBar = bar

        let slide = SKAction.sequence([
            .moveBy(x: 0, y: 20, duration: 0),
            .moveBy(x: 0, y: -20, duration: 0.3)
        ])
        bar.run(slide)
    }

    func updateBossHP(current: Float, max: Float) {
        bossHPBar?.update(current: current, max: max)
    }

    func hideBossHPBar() {
        bossHPBar?.removeFromParent()
        bossHPBar = nil
    }
}
