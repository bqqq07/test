import SpriteKit

final class Troll: Enemy {
    let packLeaderRadius: CGFloat = 120

    init() { super.init(type: .troll) }
    required init?(coder: NSCoder) { fatalError() }
}
