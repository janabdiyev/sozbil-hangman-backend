import Foundation

class CreditManager: ObservableObject {
    @Published var credits: Int = 0
    @Published var canWatchAd: Bool = false
    @Published var adsWatchedToday: Int = 0
    
    private let defaults = UserDefaults.standard
    private let creditsKey = "daily_credits"
    private let lastResetKey = "last_credit_reset"
    private let adsWatchedKey = "ads_watched_today"
    
    private let dailyFreeCredits = 7
    private let maxAdsPerDay = 5
    private let creditsPerAd = 3
    
    init() {
        checkDailyReset()
        loadCredits()
    }
    
    private func checkDailyReset() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        if let lastReset = defaults.object(forKey: lastResetKey) as? Date {
            let lastResetDay = calendar.startOfDay(for: lastReset)
            if today > lastResetDay {
                resetDailyCredits()
            }
        } else {
            resetDailyCredits()
        }
    }
    
    private func resetDailyCredits() {
        credits = dailyFreeCredits
        adsWatchedToday = 0
        defaults.set(Date(), forKey: lastResetKey)
        saveCredits()
    }
    
    private func loadCredits() {
        credits = defaults.integer(forKey: creditsKey)
        adsWatchedToday = defaults.integer(forKey: adsWatchedKey)
        updateAdAvailability()
    }
    
    private func saveCredits() {
        defaults.set(credits, forKey: creditsKey)
        defaults.set(adsWatchedToday, forKey: adsWatchedKey)
        updateAdAvailability()
    }
    
    private func updateAdAvailability() {
        canWatchAd = adsWatchedToday < maxAdsPerDay
    }
    
    func hasCredits() -> Bool {
        return credits > 0
    }
    
    func spendCredit() -> Bool {
        guard credits > 0 else { return false }
        credits -= 1
        saveCredits()
        return true
    }
    
    func addRewardedCredits() {
        guard canWatchAd else { return }
        credits += creditsPerAd
        adsWatchedToday += 1
        saveCredits()
    }
    
    func getRemainingAds() -> Int {
        return max(0, maxAdsPerDay - adsWatchedToday)
    }
}
