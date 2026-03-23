import Foundation

// MARK: - GuessEvaluator
// Implements the standard Wordle evaluation algorithm with correct Turkish duplicate-letter handling.
final class GuessEvaluator {

    /// Evaluates a guess against the target word and returns per-tile states.
    /// Handles duplicate letters correctly:
    ///   1. First pass marks exact matches (.correct), consuming those target characters.
    ///   2. Second pass marks remaining guess chars as .present if they appear in the
    ///      remaining (unconsumed) target characters, otherwise .absent.
    func evaluate(guess: String, target: String) -> [TileState] {
        var guessChars  = Array(guess.lowercased())
        var targetChars = Array(target.lowercased())
        let length = min(guessChars.count, targetChars.count)
        var result = Array(repeating: TileState.absent, count: length)

        // Pass 1 – correct positions
        for i in 0..<length where guessChars[i] == targetChars[i] {
            result[i]      = .correct
            guessChars[i]  = "\0"  // mark consumed
            targetChars[i] = "\0"
        }

        // Pass 2 – present letters
        for i in 0..<length {
            guard result[i] != .correct else { continue }
            if let j = targetChars.firstIndex(of: guessChars[i]) {
                result[i]      = .present
                targetChars[j] = "\0"  // consume this target char
            }
        }

        return result
    }
}
