import SpriteKit
import GameplayKit

final class GameScene: SKScene, SKPhysicsContactDelegate {

    // MARK: - Properties

    var player: Player!
    var enemies: [Enemy] = []
    var arrows: [Arrow] = []
    var coins: [Coin] = []

    var hud: HUDNode!
    var joystick: JoystickNode!

    var gameTime: TimeInterval = 0
    var lastUpdate: TimeInterval = 0
    var isGamePaused: Bool = false

    var playerStats: PlayerStats { GameManager.shared.playerStats }

    private var lastAttackTime: TimeInterval = 0
    private var activeGolem: AncientGolem?
    private var lastMinute: Int = 0
    private var reviveAvailable = true

    // Systems
    let spawnSystem    = SpawnSystem()
    let combatSystem   = CombatSystem()
    let waveSystem     = WaveSystem()
    let coinSystem     = CoinSystem()

    // MARK: - Lifecycle

    override func didMove(to view: SKView) {
        GameManager.shared.startNewSession()
        setupPhysics()
        setupBackground()
        setupPlayer()
        setupHUD()
        setupJoystick()
        configureSystems()
        AudioManager.shared.playBGM("forest_ambient.mp3")
    }

    private func setupPhysics() {
        physicsWorld.gravity = .zero
        physicsWorld.contactDelegate = self
    }

    private func setupPlayer() {
        player = Player(stats: GameManager.shared.playerStats)
        player.position = CGPoint(x: Constants.mapSize.width / 2,
                                  y: Constants.mapSize.height / 2)
        addChild(player)
        setupCamera()
    }

    private func setupCamera() {
        let cam = SKCameraNode()
        camera = cam
        addChild(cam)

        let light = SKLightNode()
        light.lightColor = UIColor(red: 1.0, green: 0.9, blue: 0.7, alpha: 1.0)
        light.falloff    = 1.2
        light.categoryBitMask = 1
        player.addChild(light)
    }

    private func setupBackground() {
        // Dark green ground
        let ground = SKSpriteNode(
            texture: .placeholder(color: UIColor(red: 0.11, green: 0.23, blue: 0.11, alpha: 1),
                                  size: Constants.mapSize),
            size: Constants.mapSize
        )
        ground.position = CGPoint(x: Constants.mapSize.width / 2, y: Constants.mapSize.height / 2)
        ground.zPosition = Constants.ZPositions.ground
        addChild(ground)

        // Grid lines for orientation
        let gridLayer = SKNode()
        gridLayer.zPosition = Constants.ZPositions.ground + 0.1
        let gridStep: CGFloat = 200
        let gridColor = UIColor(white: 1, alpha: 0.04)
        var x: CGFloat = 0
        while x <= Constants.mapSize.width {
            let line = SKShapeNode(rect: CGRect(x: x, y: 0, width: 1, height: Constants.mapSize.height))
            line.fillColor = gridColor; line.strokeColor = .clear
            gridLayer.addChild(line)
            x += gridStep
        }
        var y: CGFloat = 0
        while y <= Constants.mapSize.height {
            let line = SKShapeNode(rect: CGRect(x: 0, y: y, width: Constants.mapSize.width, height: 1))
            line.fillColor = gridColor; line.strokeColor = .clear
            gridLayer.addChild(line)
            y += gridStep
        }
        addChild(gridLayer)

        // Boundary walls
        let body = SKPhysicsBody(edgeLoopFrom: CGRect(origin: .zero, size: Constants.mapSize))
        body.categoryBitMask = 0; body.collisionBitMask = 0; body.contactTestBitMask = 0
        physicsBody = body

        addDecorations()
    }

    private func addDecorations() {
        // Trees as green circles
        for _ in 0..<50 {
            let r = CGFloat.random(in: 16...40)
            let tree = SKShapeNode(circleOfRadius: r)
            tree.fillColor = UIColor(
                red: CGFloat.random(in: 0.1...0.25),
                green: CGFloat.random(in: 0.3...0.55),
                blue: CGFloat.random(in: 0.05...0.15),
                alpha: 1
            )
            tree.strokeColor = UIColor(white: 0, alpha: 0.3)
            tree.position = CGPoint(x: CGFloat.random(in: 0...Constants.mapSize.width),
                                    y: CGFloat.random(in: 0...Constants.mapSize.height))
            tree.zPosition = Constants.ZPositions.decorations
            addChild(tree)
        }
        // Rocks as gray squares
        for _ in 0..<25 {
            let size = CGFloat.random(in: 8...18)
            let rock = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 3)
            rock.fillColor = UIColor(white: 0.45, alpha: 1)
            rock.strokeColor = .clear
            rock.position = CGPoint(x: CGFloat.random(in: 0...Constants.mapSize.width),
                                    y: CGFloat.random(in: 0...Constants.mapSize.height))
            rock.zPosition = Constants.ZPositions.decorations
            addChild(rock)
        }
    }

    private func setupHUD() {
        hud = HUDNode(screenSize: view?.bounds.size ?? CGSize(width: 390, height: 844))
        camera?.addChild(hud)
    }

    private func setupJoystick() {
        let size = view?.bounds.size ?? CGSize(width: 390, height: 844)
        joystick = JoystickNode()
        joystick.position = CGPoint(x: -size.width / 2 + 80, y: -size.height / 2 + 80)
        camera?.addChild(joystick)
    }

    private func configureSystems() {
        spawnSystem.onSpawnEnemy = { [weak self] enemy in
            guard let self = self else { return }
            self.enemies.append(enemy)
            self.addChild(enemy)
        }

        combatSystem.scene = self
        combatSystem.onEnemyKilled = { [weak self] enemy in
            self?.handleEnemyKilled(enemy)
        }
        combatSystem.onPlayerDamaged = { [weak self] dmg in
            self?.handlePlayerDamage(dmg)
        }
        combatSystem.onExplosion = { [weak self] pos, radius, exclude in
            self?.triggerExplosion(at: pos, radius: radius, excludeEnemy: exclude.first)
        }
        combatSystem.onForkArrow = { [weak self] original, pos in
            self?.forkArrow(from: original, at: pos)
        }

        waveSystem.onWaveUpgrade = { [weak self] in self?.showUpgradeScreen() }
        waveSystem.onBossSpawn   = { [weak self] in self?.spawnBoss() }

        coinSystem.scene = self
        coinSystem.onCoinCollected = { [weak self] value in
            guard let self = self else { return }
            GameManager.shared.playerStats.coins += value
            GameManager.shared.currentSession.totalCoins += value
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard !isGamePaused else { return }

        let delta = lastUpdate == 0 ? 0 : min(currentTime - lastUpdate, 0.05)
        lastUpdate = currentTime
        gameTime += delta

        // Update camera to follow player
        camera?.position = player.position

        player.update(delta: delta, joystickVector: joystick.velocity)

        updateEnemies(delta: delta)
        updateArrows(delta: delta)
        updateCoins(delta: delta)
        checkAutoAttack()
        checkPickups()

        combatSystem.applyThornAura(player: player, enemies: enemies, delta: delta)

        hud.update(
            time: gameTime,
            coins: playerStats.coins,
            hp: playerStats.currentHP,
            maxHP: playerStats.maxHP,
            kills: playerStats.kills
        )

        waveSystem.update(gameTime: gameTime)
        spawnSystem.update(delta: delta, gameTime: gameTime)

        GameManager.shared.currentSession.survivalTime = gameTime
        checkMinuteBonus()
    }

    // MARK: - Enemy Update

    private func updateEnemies(delta: TimeInterval) {
        enemies = enemies.filter { $0.parent != nil && $0.isAlive }
        for enemy in enemies {
            enemy.update(delta: delta, playerPosition: player.position)

            // Contact damage
            let dist = enemy.position.distance(to: player.position)
            let contactRadius: CGFloat = 20
            if dist < contactRadius {
                combatSystem.handlePlayerTouchEnemy(player: player, enemy: enemy, delta: delta)
            }
        }
    }

    // MARK: - Arrow Update

    private func updateArrows(delta: TimeInterval) {
        arrows = arrows.filter { $0.parent != nil }
        for arrow in arrows {
            arrow.update(delta: delta)
        }
    }

    // MARK: - Coin Update

    private func updateCoins(delta: TimeInterval) {
        coins = coins.filter { $0.parent != nil }
        for coin in coins { coin.update(delta: delta) }
    }

    // MARK: - Auto Attack

    private func checkAutoAttack() {
        let interval = playerStats.attackInterval
        guard gameTime - lastAttackTime >= interval else { return }
        guard let target = findNearestEnemy() else { return }

        for i in 0..<playerStats.multiShotCount {
            let secondTarget: Enemy? = i > 0 ? findNearestEnemy(excluding: target) : nil
            let fireAt = (i == 0) ? target : (secondTarget ?? target)
            fireArrow(toward: fireAt)
        }
        lastAttackTime = gameTime
        player.setState(.attacking)
        AudioManager.shared.playSFX("arrow_shoot.wav", on: self)
    }

    func findNearestEnemy(excluding: Enemy? = nil) -> Enemy? {
        let range = playerStats.arrowRange
        return enemies
            .filter { $0 !== excluding && $0.isAlive }
            .filter { $0.position.distance(to: player.position) <= range }
            .min { a, b in
                a.position.distance(to: player.position) <
                b.position.distance(to: player.position)
            }
    }

    func fireArrow(toward enemy: Enemy, origin: CGPoint? = nil) {
        let startPos = origin ?? player.position
        let arrow = Arrow()
        arrow.configure(from: playerStats)
        arrow.position = startPos
        arrow.startPosition = startPos

        let diff = CGPoint(x: enemy.position.x - startPos.x,
                           y: enemy.position.y - startPos.y)
        let dist = hypot(diff.x, diff.y)
        arrow.direction = dist > 0 ? CGVector(dx: diff.x / dist, dy: diff.y / dist) : CGVector(dx: 1, dy: 0)

        addChild(arrow)
        arrows.append(arrow)
    }

    // MARK: - Pickup

    private func checkPickups() {
        let _ = coinSystem.checkCollection(
            coins: coins,
            playerPosition: player.position,
            radius: playerStats.pickupRadius
        )
    }

    // MARK: - Contact Detection

    func didBegin(_ contact: SKPhysicsContact) {
        let a = contact.bodyA
        let b = contact.bodyB

        func node(mask: UInt32) -> SKNode? {
            if a.categoryBitMask & mask != 0 { return a.node }
            if b.categoryBitMask & mask != 0 { return b.node }
            return nil
        }

        if let arrow = node(mask: PhysicsCategory.arrow) as? Arrow,
           let enemy = node(mask: PhysicsCategory.enemy) as? Enemy {
            combatSystem.handleArrowHitEnemy(arrow: arrow, enemy: enemy)
            AudioManager.shared.playSFX("arrow_hit.wav", on: self)
        }

        if let coin = node(mask: PhysicsCategory.coin) as? Coin {
            coin.attract(to: player.position) { [weak self] in
                self?.coinSystem.onCoinCollected?(coin.value)
            }
        }
    }

    // MARK: - Enemy Killed

    private func handleEnemyKilled(_ enemy: Enemy) {
        GameManager.shared.playerStats.kills += 1
        GameManager.shared.currentSession.totalKills += 1
        coinSystem.spawnCoin(value: enemy.data.coins, at: enemy.position)
        let coin = Coin(value: enemy.data.coins)
        coin.position = enemy.position
        coins.append(coin)
        spawnDeathParticles(at: enemy.position, type: enemy.type)
        AudioManager.shared.playSFX("\(enemy.type.rawValue)_death.wav", on: self)
    }

    // MARK: - Player Damage

    private func handlePlayerDamage(_ amount: Float) {
        let died = player.receiveDamage(amount)
        shakeScreen(intensity: 4, duration: 0.2)
        AudioManager.shared.playSFX("player_hurt.wav", on: self)
        if died { triggerGameOver() }
    }

    // MARK: - Game Over

    private func triggerGameOver() {
        isGamePaused = true
        AudioManager.shared.stopBGM()
        shakeScreen(intensity: 20, duration: 0.5)
        AudioManager.shared.playSFX("player_death.wav", on: self)

        let delay = SKAction.wait(forDuration: 1.5)
        run(delay) { [weak self] in
            self?.showGameOverScene()
        }
    }

    private func showGameOverScene() {
        GameManager.shared.endSession()
        let scene = GameOverScene(size: size,
                                  session: GameManager.shared.currentSession,
                                  reviveAvailable: reviveAvailable)
        scene.scaleMode = scaleMode
        view?.presentScene(scene, transition: .fade(withDuration: 0.5))
    }

    func revivePlayer() {
        reviveAvailable = false
        let healAmount = GameManager.shared.playerStats.maxHP * Constants.reviveHPPercentage
        GameManager.shared.playerStats.currentHP = healAmount
        player.setState(.idle)
        isGamePaused = false
        AudioManager.shared.playSFX("revive.wav", on: self)
        AudioManager.shared.playBGM("forest_ambient.mp3")
    }

    // MARK: - Boss

    private func spawnBoss() {
        guard activeGolem == nil else { return }
        showBossWarning()

        let delay = SKAction.wait(forDuration: 2.5)
        run(delay) { [weak self] in
            guard let self = self else { return }
            let golem = AncientGolem()
            golem.position = self.randomEdgeSpawn()
            golem.onRockAttack = { [weak self] pos in self?.spawnGolemRock(at: pos) }
            self.addChild(golem)
            self.enemies.append(golem)
            self.activeGolem = golem
            self.hud.showBossHPBar(bossName: "ANCIENT GOLEM")
            AudioManager.shared.playBGM("boss_theme.mp3")
        }
    }

    private func showBossWarning() {
        shakeScreen(intensity: 8, duration: 0.4)
        AudioManager.shared.playSFX("boss_warning.wav", on: self)

        guard let cam = camera else { return }
        let warning = SKLabelNode(fontNamed: Constants.Fonts.primary)
        warning.text = "⚠️ ANCIENT GOLEM ⚠️"
        warning.fontSize = 16
        warning.fontColor = SKColor(hex: "#E74C3C")
        warning.zPosition = Constants.ZPositions.hud + 1
        cam.addChild(warning)

        let anim = SKAction.sequence([
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ])
        warning.run(anim)
    }

    private func spawnGolemRock(at target: CGPoint) {
        // Shadow warning
        let shadow = SKShapeNode(circleOfRadius: 40)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.4)
        shadow.strokeColor = SKColor(hex: "#E74C3C")
        shadow.position = target
        shadow.zPosition = Constants.ZPositions.entities - 0.5
        addChild(shadow)

        let blink = SKAction.sequence([
            .fadeAlpha(to: 0.2, duration: 0.3),
            .fadeAlpha(to: 0.8, duration: 0.3)
        ])

        shadow.run(.sequence([
            .repeat(blink, count: 2),
            .removeFromParent(),
            .run { [weak self] in
                self?.dropRock(at: target)
            }
        ]))
    }

    private func dropRock(at pos: CGPoint) {
        // AoE damage
        let affectedEnemies: [Enemy] = []
        let dmg: Float = 60
        let died = player.receiveDamage(
            player.position.distance(to: pos) <= 80 ? dmg : 0
        )
        if died { triggerGameOver() }

        shakeScreen(intensity: 10, duration: 0.3)
        spawnRockParticles(at: pos)
    }

    private func randomEdgeSpawn() -> CGPoint {
        let margin: CGFloat = 100
        let w = Constants.mapSize.width
        let h = Constants.mapSize.height
        let side = Int.random(in: 0..<4)
        switch side {
        case 0: return CGPoint(x: CGFloat.random(in: 0...w), y: player.position.y - margin)
        case 1: return CGPoint(x: CGFloat.random(in: 0...w), y: player.position.y + margin)
        case 2: return CGPoint(x: player.position.x - margin, y: CGFloat.random(in: 0...h))
        default: return CGPoint(x: player.position.x + margin, y: CGFloat.random(in: 0...h))
        }
    }

    // MARK: - Upgrade

    private func showUpgradeScreen() {
        isGamePaused = true
        AudioManager.shared.playSFX("level_up.wav", on: self)
        AudioManager.shared.pauseBGM()

        let upgrades = UpgradeSystem.pickThreeUpgrades()
        guard !upgrades.isEmpty else {
            isGamePaused = false
            return
        }

        let overlay = UpgradeScene(size: size, upgrades: upgrades) { [weak self] picked in
            GameManager.shared.applyUpgrade(picked)
            self?.isGamePaused = false
            AudioManager.shared.resumeBGM()
            AudioManager.shared.playSFX("upgrade_select.wav", on: self!)
        }
        overlay.scaleMode = scaleMode
        view?.presentScene(overlay, transition: .crossFade(withDuration: 0.3))
    }

    // MARK: - Minute Bonus

    private func checkMinuteBonus() {
        let currentMinute = Int(gameTime / 60)
        if currentMinute > lastMinute {
            lastMinute = currentMinute
            let bonus = coinSystem.minuteBonus(gameTime: gameTime)
            if bonus > 0 {
                GameManager.shared.playerStats.coins += bonus
                GameManager.shared.currentSession.totalCoins += bonus
                showBonusLabel("+\(bonus) coins!")
            }
        }
    }

    private func showBonusLabel(_ text: String) {
        guard let cam = camera else { return }
        let label = SKLabelNode(fontNamed: Constants.Fonts.primary)
        label.text = text
        label.fontSize = 14
        label.fontColor = SKColor(hex: "#F4D03F")
        label.position = CGPoint(x: 0, y: 40)
        label.zPosition = Constants.ZPositions.hud
        cam.addChild(label)
        label.run(.sequence([
            .moveBy(x: 0, y: 30, duration: 1.0),
            .fadeOut(withDuration: 0.3),
            .removeFromParent()
        ]))
    }

    // MARK: - Effects

    func shakeScreen(intensity: CGFloat = 8, duration: TimeInterval = 0.3) {
        guard let camera = self.camera else { return }
        let count  = Int(duration / 0.05)
        var actions: [SKAction] = (0..<count).map { _ in
            .moveBy(x: CGFloat.random(in: -intensity...intensity),
                    y: CGFloat.random(in: -intensity...intensity),
                    duration: 0.05)
        }
        actions.append(.run { [weak self] in
            camera.position = self?.player.position ?? .zero
        })
        camera.run(.sequence(actions))
    }

    private func spawnDeathParticles(at pos: CGPoint, type: EnemyType) {
        let count = type == .ancientGolem ? 20 : 8
        let color = type == .ancientGolem ? SKColor(hex: "#7A7A7A") : SKColor(hex: "#C0392B")
        for _ in 0..<count {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = color
            particle.strokeColor = .clear
            particle.position = pos
            particle.zPosition = Constants.ZPositions.particles
            addChild(particle)
            let vel = CGVector(dx: CGFloat.random(in: -60...60), dy: CGFloat.random(in: -60...60))
            particle.run(.sequence([
                .group([
                    .moveBy(x: vel.dx, y: vel.dy, duration: 0.5),
                    .sequence([.wait(forDuration: 0.3), .fadeOut(withDuration: 0.2)])
                ]),
                .removeFromParent()
            ]))
        }
    }

    private func spawnRockParticles(at pos: CGPoint) {
        for _ in 0..<12 {
            let p = SKShapeNode(rectOf: CGSize(width: 6, height: 6))
            p.fillColor = SKColor(hex: "#7A7A7A")
            p.strokeColor = .clear
            p.position = pos
            p.zPosition = Constants.ZPositions.particles
            addChild(p)
            let vel = CGVector(dx: CGFloat.random(in: -80...80), dy: CGFloat.random(in: -80...80))
            p.run(.sequence([
                .group([.moveBy(x: vel.dx, y: vel.dy, duration: 0.6),
                        .sequence([.wait(forDuration: 0.4), .fadeOut(withDuration: 0.2)])]),
                .removeFromParent()
            ]))
        }
    }

    private func triggerExplosion(at pos: CGPoint, radius: CGFloat, excludeEnemy: Enemy?) {
        let circle = SKShapeNode(circleOfRadius: radius)
        circle.fillColor = SKColor(hex: "#E67E22").withAlphaComponent(0.5)
        circle.strokeColor = .clear
        circle.position = pos
        circle.zPosition = Constants.ZPositions.particles
        addChild(circle)
        circle.run(.sequence([
            .scale(to: 1.3, duration: 0.15),
            .fadeOut(withDuration: 0.2),
            .removeFromParent()
        ]))
        AudioManager.shared.playSFX("explosion.wav", on: self)

        for enemy in enemies where enemy.isAlive && enemy !== excludeEnemy {
            if enemy.position.distance(to: pos) <= radius {
                if enemy.takeDamage(GameManager.shared.playerStats.attackDamage * 0.5) {
                    handleEnemyKilled(enemy)
                }
            }
        }

        let playerDist = player.position.distance(to: pos)
        if playerDist <= radius * 0.5 {
            let died = player.receiveDamage(10)
            if died { triggerGameOver() }
        }
    }

    private func forkArrow(from original: Arrow, at hitPos: CGPoint) {
        let angles: [CGFloat] = [.pi / 6, -.pi / 6]
        for angle in angles {
            let fork = Arrow()
            fork.configure(from: playerStats)
            fork.hasFork = false
            fork.position = hitPos

            let cos = Foundation.cos(angle)
            let sin = Foundation.sin(angle)
            let dx  = original.direction.dx * cos - original.direction.dy * sin
            let dy  = original.direction.dx * sin + original.direction.dy * cos
            fork.direction = CGVector(dx: dx, dy: dy)
            fork.startPosition = hitPos

            addChild(fork)
            arrows.append(fork)
        }
    }

    // MARK: - Touch

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches {
            let loc = touch.location(in: camera!)
            let joystickArea = CGRect(x: joystick.position.x - 80,
                                      y: joystick.position.y - 80,
                                      width: 160, height: 160)
            if joystickArea.contains(loc) {
                joystick.handleTouchBegan(touch, in: camera!)
            }
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { joystick.handleTouchMoved(touch, in: camera!) }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { joystick.handleTouchEnded(touch) }
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches { joystick.handleTouchEnded(touch) }
    }
}
