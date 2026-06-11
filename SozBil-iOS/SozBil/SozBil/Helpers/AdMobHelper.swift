import SwiftUI
import GoogleMobileAds

struct BannerAdView: UIViewRepresentable {
    let adUnitID: String
    
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = adUnitID
        banner.rootViewController = getRootViewController()
        banner.load(Request())
        return banner
    }
    
    func updateUIView(_ uiView: BannerView, context: Context) {}
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return nil
        }
        return root
    }
}

class RewardedAdManager: NSObject, ObservableObject, FullScreenContentDelegate {
    @Published var isReady = false
    @Published var isLoading = false
    
    private var rewardedAd: RewardedAd?
    private let adUnitID: String
    private var rewardCallback: ((Int, String) -> Void)?
    
    init(adUnitID: String) {
        self.adUnitID = adUnitID
        super.init()
    }
    
    func load() {
        guard !isLoading else { return }
        isLoading = true
        isReady = false
        
        RewardedAd.load(with: adUnitID, request: Request()) { [weak self] ad, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("Failed to load rewarded ad: \(error.localizedDescription)")
                    return
                }
                
                self?.rewardedAd = ad
                self?.rewardedAd?.fullScreenContentDelegate = self
                self?.isReady = true
            }
        }
    }
    
    func present(from viewController: UIViewController? = nil, completion: @escaping (Int, String) -> Void) {
        guard let rewardedAd = rewardedAd else { return }
        
        let rootVC = viewController ?? getRootViewController()
        guard let root = rootVC else { return }
        
        self.rewardCallback = completion
        rewardedAd.present(from: root) { [weak self] in
            let reward = rewardedAd.adReward
            DispatchQueue.main.async {
                self?.rewardCallback?(Int(truncating: reward.amount), reward.type)
            }
        }
    }
    
    private func getRootViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else {
            return nil
        }
        return root
    }
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        load()
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        print("Rewarded ad failed to present: \(error.localizedDescription)")
        load()
    }
}
