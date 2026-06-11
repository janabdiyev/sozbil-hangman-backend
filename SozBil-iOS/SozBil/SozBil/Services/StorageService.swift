import Foundation

class StorageService {
    static let shared = StorageService()
    private let usedWordsKey = "used_words"
    private let defaults = UserDefaults.standard
    
    func getUsedWords() -> Set<String> {
        if let array = defaults.array(forKey: usedWordsKey) as? [String] {
            return Set(array)
        }
        return Set<String>()
    }
    
    func saveUsedWords(_ words: Set<String>) {
        defaults.set(Array(words), forKey: usedWordsKey)
    }
    
    func addUsedWord(_ word: String) {
        var words = getUsedWords()
        words.insert(word.lowercased().trimmingCharacters(in: .whitespaces))
        saveUsedWords(words)
    }
    
    func resetUsedWords() {
        saveUsedWords(Set<String>())
    }
}