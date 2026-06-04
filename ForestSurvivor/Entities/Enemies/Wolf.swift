import SpriteKit

final class Wolf: Enemy {
    init() { super.init(type: .wolf) }
    required init?(coder: NSCoder) { fatalError() }
}
