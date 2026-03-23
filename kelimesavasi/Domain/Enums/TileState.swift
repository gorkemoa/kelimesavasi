import Foundation

enum TileState: String, Codable, Equatable, Sendable {
    case empty    // no letter entered
    case filled   // letter entered, not yet submitted
    case correct  // right letter, right position
    case present  // right letter, wrong position
    case absent   // letter not in word
}
