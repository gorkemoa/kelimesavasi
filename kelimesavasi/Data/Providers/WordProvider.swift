import Foundation

// MARK: - Error
enum WordProviderError: Error, LocalizedError {
    case fileNotFound
    case fileUnreadable(underlying: Error)
    case noValidWords

    var errorDescription: String? {
        switch self {
        case .fileNotFound: return "kelimeler.txt bulunamadı."
        case .fileUnreadable(let e): return "Dosya okunamadı: \(e.localizedDescription)"
        case .noValidWords: return "Geçerli kelime bulunamadı."
        }
    }
}

// MARK: - In-memory word database
struct WordDatabase: Sendable {
    let targetWords: [String]       // pure, 5-letter lowercase words used as answers
    let validGuesses: Set<String>   // all lowercase words of any length for validation

    func randomTarget(length: Int) -> String? {
        targetWords.filter { $0.count == length }.randomElement()
    }

    func isValid(_ word: String, length: Int) -> Bool {
        word.count == length && validGuesses.contains(word.lowercased())
    }
}

// MARK: - Provider actor (runs off MainActor for I/O)
actor WordProvider {
    private var cache: WordDatabase?

    func load() throws -> WordDatabase {
        if let cached = cache { return cached }
        let db = try parse()
        cache = db
        return db
    }

    private func parse() throws -> WordDatabase {
        guard let url = Bundle.main.url(
            forResource: AppConstants.wordFileName,
            withExtension: AppConstants.wordFileExtension
        ) else {
            throw WordProviderError.fileNotFound
        }

        let content: String
        do {
            content = try String(contentsOf: url, encoding: .utf8)
        } catch {
            throw WordProviderError.fileUnreadable(underlying: error)
        }

        let lines = content.components(separatedBy: .newlines)

        // Filter: non-empty, letters only (handles Turkish chars via CharacterSet.letters),
        // no spaces, slashes or digits.
        let allWords: [String] = lines.compactMap { line -> String? in
            let trimmed = line.trimmingCharacters(in: .whitespaces).lowercased()
            guard !trimmed.isEmpty,
                  trimmed.unicodeScalars.allSatisfy({ CharacterSet.letters.contains($0) }) else {
                return nil
            }
            return trimmed
        }

        guard !allWords.isEmpty else { throw WordProviderError.noValidWords }

        let fiveLetterWords = allWords.filter { $0.count == 5 }
        let validSet = Set(allWords)

        return WordDatabase(targetWords: fiveLetterWords, validGuesses: validSet)
    }
}
