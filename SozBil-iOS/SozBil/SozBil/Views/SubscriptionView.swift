import SwiftUI
import StoreKit

struct SubscriptionView: View {
    @ObservedObject var subscriptionManager: SubscriptionManager
    @Environment(\.dismiss) var dismiss
    @State private var isPurchasing = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(spacing: 8) {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.orange)
                    
                    Text("Sozbil Premium")
                        .font(.system(size: 26, weight: .bold))
                    
                    Text("Çäksiz oýun oýnaň!")
                        .font(.system(size: 15))
                        .foregroundColor(.gray)
                }
                .padding(.top, 20)
                
                VStack(alignment: .leading, spacing: 10) {
                    FeatureRow(icon: "infinity", text: "Çäksiz oýun")
                    FeatureRow(icon: "timer", text: "Gündelik çäklendirme ýok")
                    FeatureRow(icon: "tv", text: "Reklama ýok")
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                .cornerRadius(12)
                .padding(.horizontal, 16)
                
                VStack(spacing: 10) {
                    ForEach(subscriptionManager.products, id: \.id) { product in
                        SubscriptionButton(
                            product: product,
                            isPurchasing: $isPurchasing
                        ) {
                            Task {
                                isPurchasing = true
                                do {
                                    try await subscriptionManager.purchase(product)
                                    dismiss()
                                } catch {
                                    print("Purchase failed: \(error)")
                                }
                                isPurchasing = false
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                
                Button("Satyn alynanlary dikelt") {
                    Task {
                        await subscriptionManager.restorePurchases()
                        if subscriptionManager.isPremium {
                            dismiss()
                        }
                    }
                }
                .font(.system(size: 13))
                .foregroundColor(.blue)
                
                // ✅ Required subscription disclosure + legal links
                VStack(spacing: 8) {
                    Text("Abunalyk awtomatiki täzelenyär. Töleg Apple ID hasabyňyz arkaly alynýar we wagtyndan 24 sagat öň hasabyňyz bellenen bahadan tölenýär (aýlyk ýa-da ýyllyk). Abunalygy dolandyrmak ýa-da bes etmek üçin: iPhone Sazlamalar → Apple ID → Subscriptions.")
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 18)
                    
                    HStack(spacing: 18) {
                        Link("Terms of Use (EULA)", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Link("Privacy Policy", destination: URL(string: "https://sozbil-hangman-backend.onrender.com/privacy-policy.html")!)
                    }
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.blue)
                }
                .padding(.top, 6)
                
                Spacer()
            }
            .navigationTitle("Sozbil Premium")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Ýap") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.blue)
                .frame(width: 20)
                .font(.system(size: 14))
            
            Text(text)
                .font(.system(size: 14))
            
            Spacer()
        }
    }
}

struct SubscriptionButton: View {
    let product: Product
    @Binding var isPurchasing: Bool
    let action: () -> Void
    
    var isYearly: Bool {
        product.id.contains("yearly")
    }
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isYearly ? "Yearly" : "Monthly")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(product.displayPrice)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                if isYearly {
                    Text("Iň gowy")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.orange)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity)
            .background(isYearly ? Color.orange : Color.blue)
            .cornerRadius(10)
        }
        .disabled(isPurchasing)
        .opacity(isPurchasing ? 0.6 : 1.0)
    }
}
