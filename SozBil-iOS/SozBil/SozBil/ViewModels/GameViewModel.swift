import Foundation
import AVFoundation

class GameViewModel: ObservableObject {
    @Published var currentWord: HangmanWord?
    @Published var guessedLetters: Set<Character> = []
    @Published var wrongGuesses: Int = 0
    @Published var gameOver: Bool = false
    @Published var won: Bool = false
    @Published var gamesPlayed: Int = 0
    @Published var showBanner: Bool = true
    @Published var showRewarded: Bool = false
    @Published var isLoading: Bool = false
    @Published var showNoCreditAlert: Bool = false
    @Published var showRewardedAdPrompt: Bool = false
    
    let maxWrongGuesses = 6
    let maxRetry = 40
    private var audioPlayer: AVAudioPlayer?
    
    var creditManager: CreditManager?
    var subscriptionManager: SubscriptionManager?
    
    func loadNewWord() {
        // Premium users play unlimited
        if let subManager = subscriptionManager, subManager.isPremium {
            startNewGame()
            return
        }
        
        guard let creditMgr = creditManager else {
            startNewGame()
            return
        }
        
        // If user has credits, spend one and play
        if creditMgr.hasCredits() {
            if creditMgr.spendCredit() {
                startNewGame()
            }
            return
        }
        
        // User has 0 credits - check if they can watch an ad
        if creditMgr.canWatchAd {
            // Offer rewarded ad to get more credits
            showRewardedAdPrompt = true
        } else {
            // Can't watch more ads today - show subscription prompt
            showNoCreditAlert = true
        }
    }
    
    private func startNewGame() {
        guessedLetters.removeAll()
        wrongGuesses = 0
        gameOver = false
        won = false
        showRewarded = false
        showRewardedAdPrompt = false
        isLoading = true
        
        fetchNonRepeatedWord()
    }
    
    private func fetchNonRepeatedWord(retry: Int = 0) {
        if retry > maxRetry {
            StorageService.shared.resetUsedWords()
        }
        
        let usedWords = StorageService.shared.getUsedWords()
        
        APIService.shared.fetchRandomWord { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let word):
                    let normalized = word.word.lowercased().trimmingCharacters(in: .whitespaces)
                    
                    if usedWords.contains(normalized) {
                        self?.fetchNonRepeatedWord(retry: retry + 1)
                        return
                    }
                    
                    StorageService.shared.addUsedWord(normalized)
                    self?.currentWord = word
                    
                case .failure(let error):
                    print("Error: \(error)")
                }
            }
        }
    }
    
    func guessLetter(_ letter: Character) {
        guard !gameOver else { return }
        
        playTapSound()
        guessedLetters.insert(letter)
        
        guard let word = currentWord?.word else { return }
        
        if !word.uppercased().contains(letter.uppercased()) {
            wrongGuesses += 1
        }
        
        checkGameOver()
    }
    
    private func checkGameOver() {
        guard let word = currentWord?.word else { return }
        
        let won = word.allSatisfy { char in
            char == " " || char == "-" || char == "'" ||
            guessedLetters.contains(Character(char.uppercased()))
        }
        
        let lost = wrongGuesses >= maxWrongGuesses
        
        if won || lost {
            gameOver = true
            self.won = won
            gamesPlayed += 1
        }
    }
    
    func getDisplayWord() -> String {
        guard let word = currentWord?.word else { return "_ _ _ _ _" }
        
        return word.map { char in
            if char == " " {
                return "  "
            } else if char == "-" {
                return gameOver ? "-" : "_"
            } else if char == "'" {
                return (gameOver || guessedLetters.contains("'")) ? "'" : "_"
            } else if guessedLetters.contains(Character(char.uppercased())) || gameOver {
                return String(char)
            } else {
                return "_"
            }
        }.joined(separator: " ")
    }
    
    func isLetterGuessed(_ letter: Character) -> Bool {
        return guessedLetters.contains(letter)
    }
    
    func isLetterCorrect(_ letter: Character) -> Bool {
        guard let word = currentWord?.word else { return false }
        return word.uppercased().contains(letter.uppercased())
    }
    
    private func playTapSound() {
        AudioServicesPlaySystemSound(1104)
    }
    
    func onRewardedAdWatched() {
        // Give user the credits from watching the ad
        creditManager?.addRewardedCredits()
        
        // Close the rewarded ad prompt
        showRewardedAdPrompt = false
        
        // Immediately start a new game with the earned credits
        if let creditMgr = creditManager, creditMgr.hasCredits() {
            if creditMgr.spendCredit() {
                startNewGame()
            }
        }
    }
}
