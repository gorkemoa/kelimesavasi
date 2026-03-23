import Foundation

final class WordRepository: WordRepositoryProtocol {
    private let provider: WordProvider
    private var database: WordDatabase?

    init(provider: WordProvider = WordProvider()) {
        self.provider = provider
    }

    func loadIfNeeded() async throws {
        guard database == nil else { return }
        do {
            database = try await provider.load()
        } catch {
            throw WordRepositoryError.loadFailed(underlying: error)
        }
    }

    func randomTargetWord(length: Int = AppConstants.defaultWordLength) async throws -> String {
        if database == nil { try await loadIfNeeded() }
        guard let db = database, let word = db.randomTarget(length: length) else {
            throw WordRepositoryError.noWordsAvailable
        }
        return word
    }

    func isValid(word: String, length: Int = AppConstants.defaultWordLength) async -> Bool {
        if database == nil { try? await loadIfNeeded() }
        guard let db = database else { return false }
        return db.isValid(word, length: length)
    }
}
