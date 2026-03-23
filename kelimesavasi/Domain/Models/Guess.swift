import Foundation

struct Guess: Codable, Identifiable, Sendable {
    let id: String
    let word: String
    var evaluation: [TileState]
    var isEvaluated: Bool

    init(id: String = UUID().uuidString, word: String,
         evaluation: [TileState] = [], isEvaluated: Bool = false) {
        self.id = id
        self.word = word
        self.evaluation = evaluation
        self.isEvaluated = isEvaluated
    }

    var isCorrect: Bool {
        isEvaluated && evaluation.allSatisfy { $0 == .correct }
    }
}
