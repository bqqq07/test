import SpriteKit
import UIKit

// MARK: - CGPoint Math

extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        return hypot(other.x - x, other.y - y)
    }

    func normalized() -> CGPoint {
        let len = hypot(x, y)
        guard len > 0 else { return .zero }
        return CGPoint(x: x / len, y: y / len)
    }

    static func + (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }

    static func - (lhs: CGPoint, rhs: CGPoint) -> CGPoint {
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }

    static func * (lhs: CGPoint, rhs: CGFloat) -> CGPoint {
        return CGPoint(x: lhs.x * rhs, y: lhs.y * rhs)
    }
}

extension CGVector {
    var length: CGFloat { hypot(dx, dy) }

    func normalized() -> CGVector {
        let len = length
        guard len > 0 else { return .zero }
        return CGVector(dx: dx / len, dy: dy / len)
    }
}

// MARK: - SKColor Hex

extension SKColor {
    convenience init(hex: String) {
        var hexStr = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexStr.hasPrefix("#") { hexStr.removeFirst() }
        var rgb: UInt64 = 0
        Scanner(string: hexStr).scanHexInt64(&rgb)
        let r = CGFloat((rgb >> 16) & 0xFF) / 255.0
        let g = CGFloat((rgb >> 8)  & 0xFF) / 255.0
        let b = CGFloat(rgb         & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b, alpha: 1.0)
    }
}

// MARK: - TimeInterval Formatting

extension TimeInterval {
    var mmss: String {
        let m = Int(self) / 60
        let s = Int(self) % 60
        return String(format: "%d:%02d", m, s)
    }
}

// MARK: - SKNode

extension SKNode {
    func removeAllChildrenOfType<T: SKNode>(_ type: T.Type) {
        children.compactMap { $0 as? T }.forEach { $0.removeFromParent() }
    }
}
