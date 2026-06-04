import SpriteKit

final class CoinSystem {
    weak var scene: SKScene?
    var onCoinCollected: ((Int) -> Void)?

    func spawnCoin(value: Int, at position: CGPoint) {
        guard let scene = scene else { return }
        let coin = Coin(value: value)
        coin.position = position
        scene.addChild(coin)
    }

    func checkCollection(coins: [Coin], playerPosition: CGPoint, radius: CGFloat) -> [Coin] {
        var collected: [Coin] = []
        for coin in coins {
            guard coin.parent != nil else { continue }
            let dist = coin.position.distance(to: playerPosition)
            if dist <= radius {
                coin.attract(to: playerPosition) { [weak self] in
                    self?.onCoinCollected?(coin.value)
                }
                collected.append(coin)
            }
        }
        return collected
    }

    func minuteBonus(gameTime: TimeInterval) -> Int {
        let minutes = Int(gameTime / 60)
        if minutes == 0 { return 0 }
        if minutes == 1 { return 25 }
        return 25 + (minutes - 1) * 5
    }
}
