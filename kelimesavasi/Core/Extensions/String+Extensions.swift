import Foundation

extension String {
    /// Normalized lowercase version for comparison (Turkish-aware lowercasing and circumflex removal).
    var normalizedForGame: String {
        self.lowercased(with: Locale(identifier: "tr"))
            .replacingOccurrences(of: "â", with: "a")
            .replacingOccurrences(of: "î", with: "i")
            .replacingOccurrences(of: "û", with: "u")
    }

    /// Uppercased version for display (Turkish-aware uppercasing).
    var uppercasedForGame: String {
        self.uppercased(with: Locale(identifier: "tr"))
    }

    /// Returns an array of single-character strings for each Unicode character.
    var characters: [String] {
        map { String($0) }
    }

    /// Whether the string contains only letter characters (including Turkish special chars).
    var isAllLetters: Bool {
        !isEmpty && unicodeScalars.allSatisfy { CharacterSet.letters.contains($0) }
    }

    /// Pads or trims the string to a given length using the given pad character.
    func padded(toLength length: Int, with pad: Character = " ") -> String {
        if count >= length { return String(prefix(length)) }
        return self + String(repeating: pad, count: length - count)
    }
}
