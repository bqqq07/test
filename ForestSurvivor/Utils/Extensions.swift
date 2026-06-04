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

// MARK: - Placeholder Textures (used when real sprites are missing)

extension SKTexture {
    static func placeholder(color: UIColor, size: CGSize) -> SKTexture {
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()!
        // Fill
        ctx.setFillColor(color.cgColor)
        ctx.fill(CGRect(origin: .zero, size: size))
        // Border
        ctx.setStrokeColor(UIColor.white.withAlphaComponent(0.6).cgColor)
        ctx.setLineWidth(2)
        ctx.stroke(CGRect(x: 1, y: 1, width: size.width - 2, height: size.height - 2))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return SKTexture(image: img)
    }

    static func circle(color: UIColor, radius: CGFloat) -> SKTexture {
        let size = CGSize(width: radius * 2, height: radius * 2)
        UIGraphicsBeginImageContextWithOptions(size, false, 1)
        let ctx = UIGraphicsGetCurrentContext()!
        ctx.setFillColor(color.cgColor)
        ctx.fillEllipse(in: CGRect(origin: .zero, size: size))
        let img = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        return SKTexture(image: img)
    }
}

// MARK: - Safe imageNamed (falls back to colored placeholder)

extension SKSpriteNode {
    static func safe(imageNamed name: String, size: CGSize, fallbackColor: UIColor) -> SKSpriteNode {
        // Try loading the real texture; if it's the default missing-asset checkerboard, use placeholder
        let texture = SKTexture(imageNamed: name)
        let node = SKSpriteNode(texture: texture, size: size)
        // If texture couldn't load it returns a 64×64 default — check by filtering on name
        // We just always have a color fallback baked in via the color property
        node.color = fallbackColor
        node.colorBlendFactor = texture.size().width < 8 ? 1.0 : 0.0
        return node
    }
}
