import SwiftUI

struct GameView: View {
    @StateObject private var viewModel = GameViewModel()
    @StateObject private var creditManager = CreditManager()
    @StateObject private var subscriptionManager = SubscriptionManager()
    @StateObject private var rewarded = RewardedAdManager(adUnitID: "ca-app-pub-7668467791782601/4998185896")
    @State private var showSubscription = false
    
    private var isIPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
    
    private var hangmanHeight: CGFloat {
        isIPad ? 500 : 240
    }
    
    private var hangmanWidth: CGFloat {
        isIPad ? 150 : 240
    }
    
    private var cardPadding: CGFloat {
        isIPad ? 24 : 14
    }
    
    private var wordFontSize: CGFloat {
        isIPad ? 44 : 34
    }
    
    private var hintFontSize: CGFloat {
        isIPad ? 18 : 15
    }
    
    private var verticalSpacing: CGFloat {
        isIPad ? 20 : 10
    }
    
    private var topBottomPadding: CGFloat {
        isIPad ? 20 : 10
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                HStack {
                    HStack(spacing: 8) {
                        Image("logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                        
                        Text("Sözbil")
                            .font(.system(size: 25, weight: .bold))
                            .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
                    }
                    
                    Spacer()
                    
                    if !subscriptionManager.isPremium {
                        Button {
                            showSubscription = true
                        } label: {
                            Image(systemName: "crown.fill")
                                .foregroundColor(.orange)
                                .font(.system(size: 18))
                        }
                        .padding(.trailing, 8)
                        
                        HStack(spacing: 4) {
                            Text("\(creditManager.credits)")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.blue)
                            
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.system(size: 16))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color(red: 0.95, green: 0.95, blue: 0.95))
                        .cornerRadius(20)
                    } else {
                        Text("Premium")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange)
                            .cornerRadius(20)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, topBottomPadding)
                .padding(.bottom, topBottomPadding)

                VStack(spacing: verticalSpacing) {
                    HangmanView(wrongGuesses: viewModel.wrongGuesses)
                        .frame(height: hangmanHeight)

                    Text("\(viewModel.maxWrongGuesses - viewModel.wrongGuesses)/\(viewModel.maxWrongGuesses) harp galdy")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white)
                        .cornerRadius(8)

                    if viewModel.isLoading {
                        Text("Loading...")
                            .font(.system(size: wordFontSize, weight: .bold))
                            .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
                    } else {
                        Text(viewModel.getDisplayWord())
                            .font(.system(size: wordFontSize, weight: .bold))
                            .foregroundColor(Color(red: 0.07, green: 0.07, blue: 0.07))
                            .kerning(0.1)
                            .lineLimit(1)
                            .minimumScaleFactor(0.5)
                    }

                    if let hint = viewModel.currentWord?.hint {
                        Text("Ýardam: \(hint)")
                            .font(.system(size: hintFontSize))
                            .foregroundColor(Color(red: 0.27, green: 0.27, blue: 0.27))
                            .multilineTextAlignment(.center)
                    }
                }
                .padding(cardPadding)
                .background(Color(red: 0.97, green: 0.97, blue: 0.97))
                .cornerRadius(8)
                .padding(.horizontal, 16)

                Text("Harp saýla")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.2, blue: 0.2))
                    .padding(.top, isIPad ? 24 : 14)
                    .padding(.bottom, 8)

                KeyboardView(viewModel: viewModel, isIPad: isIPad)

                // Banner ad — always visible during play for non-premium users
                if !subscriptionManager.isPremium {
                    BannerAdView(adUnitID: "ca-app-pub-7668467791782601/8011362046")
                        .frame(height: 50)
                        .padding(.top, 8)
                }

                if viewModel.gameOver {
                    VStack(spacing: 12) {
                        Text(viewModel.won ? "🎉 Bildiň!" : "☠️ Bilmediň!\nSöz: \(viewModel.currentWord?.word.uppercased() ?? "")")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(viewModel.won ? Color(red: 0.18, green: 0.49, blue: 0.20) : Color.red)
                            .multilineTextAlignment(.center)
                            .padding(.top, 10)

                        Button(action: {
                            viewModel.loadNewWord()
                        }) {
                            Text("Täzeden oýna")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 52)
                                .background(Color.blue)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 16)

                        if viewModel.showRewarded && creditManager.canWatchAd {
                            Button {
                                rewarded.present { amount, type in
                                    creditManager.addRewardedCredits()
                                }
                                viewModel.showRewarded = false
                            } label: {
                                Text(rewarded.isReady ? "Reklama görüp oýuna dowam et!" : "Reklama taýýarlanýar...")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(rewarded.isReady ? Color.green : Color.gray)
                                    .cornerRadius(8)
                            }
                            .padding(.horizontal, 16)
                            .padding(.top, 6)
                            .disabled(!rewarded.isReady)
                            
                            if creditManager.getRemainingAds() > 0 {
                                Text("Galan reklama: \(creditManager.getRemainingAds())")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                // No credits block — rewarded ad offered before Premium upsell
                if !subscriptionManager.isPremium && creditManager.credits == 0 {
                    VStack(spacing: 12) {
                        Text("Kredit gutardy!")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.red)
                            .padding(.top, 20)

                        if creditManager.canWatchAd {
                            Button {
                                rewarded.present { _, _ in
                                    creditManager.addRewardedCredits()
                                }
                            } label: {
                                Text(rewarded.isReady ? "Reklama gör (+3 kredit)" : "Reklama taýýarlanýar...")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(rewarded.isReady ? Color.green : Color.gray)
                                    .cornerRadius(8)
                            }
                            .disabled(!rewarded.isReady)
                            .padding(.horizontal, 15)

                            Text("Galan reklama: \(creditManager.getRemainingAds())")
                                .font(.system(size: 13))
                                .foregroundColor(.gray)
                        }

                        Button {
                            showSubscription = true
                        } label: {
                            Text("Premium Al")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.orange)
                                .cornerRadius(8)
                        }
                        .padding(.horizontal, 15)
                    }
                }
            }
            .padding(.bottom, 16)
        }
        .background(Color.white)
        .onAppear {
            viewModel.creditManager = creditManager
            viewModel.subscriptionManager = subscriptionManager
            viewModel.loadNewWord()
            rewarded.load()
        }
        .onChange(of: viewModel.showRewarded) { newValue in
            if newValue && !rewarded.isReady && !rewarded.isLoading {
                rewarded.load()
            }
        }
        .alert("Kredit gutardy", isPresented: $viewModel.showNoCreditAlert) {
            if creditManager.canWatchAd {
                Button("Reklama gör (+3 kredit)") {
                    rewarded.present { _, _ in
                        creditManager.addRewardedCredits()
                        viewModel.loadNewWord()
                    }
                }
            }
            Button("Premium Al") {
                showSubscription = true
            }
            Button("Ýap", role: .cancel) {}
        } message: {
            if creditManager.canWatchAd {
                Text("Reklama görüp goşmaça kredit alyň ýa-da Premium görnüşine geçiň")
            } else {
                Text("Ertir täze kreditler bolar ýa-da Premium görnüşine geçiň")
            }
        }
        .sheet(isPresented: $showSubscription) {
            SubscriptionView(subscriptionManager: subscriptionManager)
        }
    }
}