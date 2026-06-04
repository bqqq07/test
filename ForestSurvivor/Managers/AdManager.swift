import UIKit

// AdManager wraps Google Mobile Ads (GAD).
// Import GoogleMobileAds via SPM and uncomment the GAD code below.

final class AdManager: NSObject {
    static let shared = AdManager()

    var isAdFree: Bool { SaveManager.shared.isAdFree }
    private var interstitialCount = 0
    var onRewardEarned: (() -> Void)?

    private override init() { super.init() }

    // MARK: - Interstitial

    func loadInterstitial() {
        guard !isAdFree else { return }
        // GADInterstitialAd.load(withAdUnitID: "ca-app-pub-xxx/xxx", request: .init()) { [weak self] ad, _ in
        //     self?.interstitial = ad
        // }
    }

    func showInterstitialIfReady(from vc: UIViewController) {
        guard !isAdFree else { return }
        interstitialCount += 1
        guard interstitialCount % 2 == 0 else { return }
        // interstitial?.present(fromRootViewController: vc)
        // loadInterstitial()
    }

    // MARK: - Rewarded

    func loadRewarded() {
        guard !isAdFree else { return }
        // GADRewardedAd.load(withAdUnitID: "ca-app-pub-xxx/xxx", request: .init()) { [weak self] ad, _ in
        //     self?.rewardedAd = ad
        // }
    }

    func showRewarded(from vc: UIViewController, onReward: @escaping () -> Void) {
        guard !isAdFree else {
            onReward()
            return
        }
        // guard let ad = rewardedAd else { return }
        // onRewardEarned = onReward
        // ad.present(fromRootViewController: vc) { onReward() }

        // Dev placeholder: grant reward immediately
        onReward()
    }
}
