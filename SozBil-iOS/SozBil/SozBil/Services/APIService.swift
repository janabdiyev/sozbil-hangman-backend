import Foundation

class APIService {
    static let shared = APIService()
    private let baseURL = "https://sozbil-hangman-backend.onrender.com/"
    
    func fetchRandomWord(completion: @escaping (Result<HangmanWord, Error>) -> Void) {
        guard let url = URL(string: "\(baseURL)api/word/") else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = data else {
                completion(.failure(NSError(domain: "No data", code: -1)))
                return
            }
            
            do {
                let word = try JSONDecoder().decode(HangmanWord.self, from: data)
                completion(.success(word))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}