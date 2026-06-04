import SpriteKit
import UIKit

final class GameOverScene: SKScene {
    private let session: GameSession
    private var reviveAvailable: Bool

    init(size: CGSize, session: GameSession, reviveAvailable: Bool) {
        self.session = session
        self.reviveAvailable = reviveAvailable
        super.init(size: size)
    }

    required init?(coder: NSCoder) { fatalError() }

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#0D1B0D")
        setupUI()
        AdManager.shared.loadRewarded()
        AdManager.shared.loadInterstitial()

        if let vc = view.window?.rootViewController {
            AdManager.shared.showInterstitialIfReady(from: vc)
        }
    }

    private func setupUI() {
        // Title
        addLabel("💀 YOU DIED", y: size.height * 0.78, font: Constants.Fonts.primary,
                 size: 20, color: "#E74C3C")

        // Stats
        let save = SaveManager.shared
        let stats: [(String, String)] = [
            ("Time",    session.survivalTime.mmss),
            ("Coins",   "\(session.totalCoins)"),
            ("Kills",   "\(session.totalKills)"),
            ("Best",    save.highScoreTime.mmss)
        ]

        for (i, (label, value)) in stats.enumerated() {
            let y = size.height * 0.62 - CGFloat(i) * 32
            addStatRow(label: label, value: value, y: y)
        }

        // Buttons
        if reviveAvailable {
            addButton(text: "🎥 REVIVE", position: CGPoint(x: size.width / 2, y: size.height * 0.32),
                      name: "revive")
        }
        addButton(text: "🔄 TRY AGAIN", position: CGPoint(x: size.width / 2, y: size.height * 0.22),
                  name: "retry")
        addButton(text: "🏠 MAIN MENU", position: CGPoint(x: size.width / 2, y: size.height * 0.12),
                  name: "menu")
    }

    private func addLabel(_ text: String, y: CGFloat, font: String, size fontSize: CGFloat, color: String) {
        let label = SKLabelNode(fontNamed: font)
        label.text = text
        label.fontSize = fontSize
        label.fontColor = SKColor(hex: color)
        label.position = CGPoint(x: size.width / 2, y: y)
        label.horizontalAlignmentMode = .center
        addChild(label)
    }

    private func addStatRow(label: String, value: String, y: CGFloat) {
        let row = SKNode()
        row.position = CGPoint(x: size.width / 2, y: y)

        let keyLabel = SKLabelNode(fontNamed: Constants.Fonts.body)
        keyLabel.text = label + ":"
        keyLabel.fontSize = 18
        keyLabel.fontColor = SKColor(hex: "#B8B5B0")
        keyLabel.position = CGPoint(x: -60, y: 0)
        keyLabel.horizontalAlignmentMode = .right

        let valLabel = SKLabelNode(fontNamed: Constants.Fonts.primary)
        valLabel.text = value
        valLabel.fontSize = 14
        valLabel.fontColor = SKColor(hex: "#F0EDE8")
        valLabel.position = CGPoint(x: 60, y: 0)
        valLabel.horizontalAlignmentMode = .left

        row.addChild(keyLabel)
        row.addChild(valLabel)
        addChild(row)
    }

    private func addButton(text: String, position: CGPoint, name: String) {
        let bg = SKShapeNode(rectOf: CGSize(width: 200, height: 44), cornerRadius: 8)
        bg.fillColor   = SKColor(hex: "#252540")
        bg.strokeColor = SKColor(hex: "#3A3A5C")
        bg.position    = position
        bg.name        = name
        addChild(bg)

        let label = SKLabelNode(fontNamed: Constants.Fonts.primary)
        label.text = text
        label.fontSize = 11
        label.fontColor = SKColor(hex: "#F0EDE8")
        label.verticalAlignmentMode = .center
        label.name = name
        bg.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let hit = nodes(at: touch.location(in: self))
        for node in hit {
            switch node.name {
            case "revive":   handleRevive()
            case "retry":    startNewGame()
            case "menu":     goToMenu()
            default: break
            }
        }
    }

    private func handleRevive() {
        guard reviveAvailable else { return }
        guard let vc = view?.window?.rootViewController else { return }
        AdManager.shared.showRewarded(from: vc) { [weak self] in
            guard let self = self else { return }
            self.reviveAvailable = false
            let gameScene = GameScene(size: self.size)
            gameScene.scaleMode = self.scaleMode
            self.view?.presentScene(gameScene, transition: .fade(withDuration: 0.5))
            // GameScene will revive the player on first load via GameManager
        }
    }

    private func startNewGame() {
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .doorway(withDuration: 0.5))
    }

    private func goToMenu() {
        let scene = MenuScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }
}
