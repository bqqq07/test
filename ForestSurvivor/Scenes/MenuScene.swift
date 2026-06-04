import SpriteKit

final class MenuScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#1A3A1A")
        setupBackground()
        setupUI()
        AudioManager.shared.playBGM("menu_theme.mp3")
    }

    private func setupBackground() {
        // Parallax forest layers
        let layers: [(String, CGFloat)] = [
            ("tree_01", 0.2),
            ("tree_02", 0.5),
            ("tree_03", 0.8)
        ]
        for (i, (name, _)) in layers.enumerated() {
            let sprite = SKSpriteNode(imageNamed: name)
            sprite.size = CGSize(width: size.width, height: size.height)
            sprite.position = CGPoint(x: size.width / 2, y: size.height / 2)
            sprite.zPosition = CGFloat(-3 + i)
            sprite.alpha = 0.6 - CGFloat(i) * 0.1
            addChild(sprite)
        }
    }

    private func setupUI() {
        // Title
        let title = SKLabelNode(fontNamed: Constants.Fonts.primary)
        title.text = "FOREST SURVIVOR"
        title.fontSize = 18
        title.fontColor = SKColor(hex: "#8BC34A")
        title.position = CGPoint(x: size.width / 2, y: size.height * 0.7)
        addChild(title)

        // High Score
        let save = SaveManager.shared
        let scoreLabel = SKLabelNode(fontNamed: Constants.Fonts.body)
        scoreLabel.text = "BEST: \(save.highScoreTime.mmss)  |  \(save.highScoreCoins) COINS"
        scoreLabel.fontSize = 16
        scoreLabel.fontColor = SKColor(hex: "#F4D03F")
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height * 0.58)
        addChild(scoreLabel)

        // Play button
        addButton(text: "▶  PLAY", position: CGPoint(x: size.width / 2, y: size.height * 0.45),
                  name: "play")

        // Sound button
        let muteLabel = SaveManager.shared.isMuted ? "🔇 SOUND OFF" : "🔊 SOUND ON"
        addButton(text: muteLabel, position: CGPoint(x: size.width / 2 - 80, y: size.height * 0.3),
                  name: "mute", small: true)

        // No Ads button
        if !SaveManager.shared.isAdFree {
            addButton(text: "★ NO ADS", position: CGPoint(x: size.width / 2 + 80, y: size.height * 0.3),
                      name: "noads", small: true)
        }
    }

    private func addButton(text: String, position: CGPoint, name: String, small: Bool = false) {
        let bg = SKShapeNode(rectOf: CGSize(width: small ? 120 : 180, height: small ? 36 : 50),
                             cornerRadius: 8)
        bg.fillColor   = SKColor(hex: "#252540")
        bg.strokeColor = SKColor(hex: "#3A3A5C")
        bg.position    = position
        bg.name        = name
        addChild(bg)

        let label = SKLabelNode(fontNamed: Constants.Fonts.primary)
        label.text     = text
        label.fontSize = small ? 9 : 14
        label.fontColor = SKColor(hex: "#F0EDE8")
        label.verticalAlignmentMode = .center
        label.name     = name
        bg.addChild(label)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let nodes = nodes(at: touch.location(in: self))
        for node in nodes {
            switch node.name {
            case "play":
                startGame()
            case "mute":
                let m = !SaveManager.shared.isMuted
                SaveManager.shared.setMuted(m)
                AudioManager.shared.isMuted = m
                (node as? SKLabelNode)?.text = m ? "🔇 SOUND OFF" : "🔊 SOUND ON"
            case "noads":
                // IAP flow would go here
                break
            default: break
            }
        }
    }

    private func startGame() {
        AudioManager.shared.stopBGM()
        let scene = GameScene(size: size)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .doorway(withDuration: 0.5))
    }
}
