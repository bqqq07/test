import SwiftUI
import SpriteKit

struct ContentView: View {
    var scene: SKScene {
        let s = SplashScene(size: UIScreen.main.bounds.size)
        s.scaleMode = .resizeFill
        return s
    }

    var body: some View {
        SpriteView(scene: scene, options: [.ignoresSiblingOrder])
            .ignoresSafeArea()
            .statusBar(hidden: true)
    }
}
