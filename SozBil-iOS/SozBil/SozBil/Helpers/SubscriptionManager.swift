import Foundation
import StoreKit

class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var currentSubscription: String = ""
    @Published var products: [Product] = []
    
    private let monthlyID = "com.sozbil.app.SozBil.monthly_premium"
    private let yearlyID = "com.sozbil.app.SozBil.yearly_premium"
    
    init() {
        Task {
            await loadProducts()
            await checkSubscriptionStatus()
        }
    }
    
    func loadProducts() async {
        do {
            let loadedProducts = try await Product.products(for: [monthlyID, yearlyID])
            await MainActor.run {
                products = loadedProducts
            }
        } catch {
            print("Failed to load products: \(error)")
        }
    }
    
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        
        switch result {
        case .success(let verification):
            let transaction = try checkVerified(verification)
            await transaction.finish()
            await checkSubscriptionStatus()
        case .userCancelled, .pending:
            break
        @unknown default:
            break
        }
    }
    
    func checkSubscriptionStatus() async {
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            
            if transaction.productID == monthlyID || transaction.productID == yearlyID {
                if transaction.expirationDate ?? Date() > Date() {
                    await MainActor.run {
                        isPremium = true
                        currentSubscription = transaction.productID
                    }
                    return
                }
            }
        }
        
        await MainActor.run {
            isPremium = false
            currentSubscription = ""
        }
    }
    
    func restorePurchases() async {
        try? await AppStore.sync()
        await checkSubscriptionStatus()
    }
    
    private func checkVerified<T>(_ result: VerificationResult<T>) throws -> T {
        switch result {
        case .unverified:
            throw StoreError.failedVerification
        case .verified(let safe):
            return safe
        }
    }
}

enum StoreError: Error {
    case failedVerification
}
