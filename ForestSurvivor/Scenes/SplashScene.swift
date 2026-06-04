import SpriteKit

final class SplashScene: SKScene {

    override func didMove(to view: SKView) {
        backgroundColor = SKColor(hex: "#0D1B0D")

        let logo = SKLabelNode(fontNamed: Constants.Fonts.primary)
        logo.text = "FOREST SURVIVOR"
        logo.fontSize = 18
        logo.fontColor = SKColor(hex: "#8BC34A")
        logo.position = CGPoint(x: size.width / 2, y: size.height / 2 + 20)
        logo.alpha = 0
        addChild(logo)

        let sub = SKLabelNode(fontNamed: Constants.Fonts.body)
        sub.text = "Loading..."
        sub.fontSize = 16
        sub.fontColor = SKColor(hex: "#4A7C3F")
        sub.position = CGPoint(x: size.width / 2, y: size.height / 2 - 20)
        sub.alpha = 0
        addChild(sub)

        let fadeIn = SKAction.sequence([
            .wait(forDuration: 0.3),
            .fadeIn(withDuration: 0.5)
        ])
        logo.run(fadeIn)
        sub.run(fadeIn)

        run(.sequence([
            .wait(forDuration: 2.5),
            .run { [weak self] in self?.transitionToMenu() }
        ]))
    }

    private func transitionToMenu() {
        let menu = MenuScene(size: size)
        menu.scaleMode = scaleMode
        view?.presentScene(menu, transition: .fade(withDuration: 0.5))
    }
}
