import SpriteKit

final class VineCreature: Enemy {
    var onSlowPlayer: ((_ duration: Float) -> Void)?

    init() { super.init(type: .vineCreature) }
    required init?(coder: NSCoder) { fatalError() }
}
