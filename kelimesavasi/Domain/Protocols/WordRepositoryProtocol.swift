import Foundation

protocol WordRepositoryProtocol: AnyObject {
    func randomTargetWord(length: Int) async throws -> String
    func isValid(word: String, length: Int) async -> Bool
    func loadIfNeeded() async throws
}

enum WordRepositoryError: Error, LocalizedError {
    case noWordsAvailable
    case loadFailed(underlying: Error)

    var errorDescription: String? {
        switch self {
        case .noWordsAvailable: return "Kelime listesi boş."
        case .loadFailed(let e): return "Kelimeler yüklenemedi: \(e.localizedDescription)"
        }
    }
}
