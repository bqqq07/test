import SwiftUI

// To enable AdMob:
// 1. Add package: https://github.com/googleads/swift-package-manager-google-mobile-ads
// 2. Import GoogleMobileAds here
// 3. Uncomment: GADMobileAds.sharedInstance().start()

@main
struct ForestSurvivorApp: App {
    init() {
        // GADMobileAds.sharedInstance().start()
        AdManager.shared.loadInterstitial()
        AdManager.shared.loadRewarded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
