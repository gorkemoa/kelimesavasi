import XCTest
@testable import kelimesavasi

// MARK: - WordProvider Tests
final class WordProviderTests: XCTestCase {

    func test_wordProvider_loadsDatabase() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        XCTAssertFalse(db.targetWords.isEmpty, "targetWords should not be empty")
        XCTAssertFalse(db.validGuesses.isEmpty, "validGuesses should not be empty")
    }

    func test_targetWords_areAllFiveLetters() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        for word in db.targetWords {
            XCTAssertEqual(word.count, 5, "Target word '\(word)' should be 5 characters")
        }
    }

    func test_targetWords_areAllLowercase() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        for word in db.targetWords.prefix(100) {
            XCTAssertEqual(word, word.lowercased(), "Word '\(word)' should be lowercase")
        }
    }

    func test_targetWords_containNoSpaces() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        for word in db.targetWords {
            XCTAssertFalse(word.contains(" "), "Word '\(word)' should contain no spaces")
        }
    }

    func test_randomTarget_returnsValidFiveLetterWord() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        guard let word = db.randomTarget(length: 5) else {
            XCTFail("randomTarget should return a word")
            return
        }
        XCTAssertEqual(word.count, 5)
        XCTAssertTrue(db.validGuesses.contains(word))
    }

    func test_isValid_recognizesKnownWord() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        guard let word = db.targetWords.first else {
            XCTFail("No words available"); return
        }
        XCTAssertTrue(db.isValid(word, length: 5))
    }

    func test_isValid_rejectsNonsenseWord() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        XCTAssertFalse(db.isValid("qqqqq", length: 5))
        XCTAssertFalse(db.isValid("zzzzz", length: 5))
    }

    func test_caching_returnsSameInstance() async throws {
        let provider = WordProvider()
        let db1 = try await provider.load()
        let db2 = try await provider.load()
        // Both should reference same cached data (same number of words)
        XCTAssertEqual(db1.targetWords.count, db2.targetWords.count)
    }

    func test_wordCount_isReasonable() async throws {
        let provider = WordProvider()
        let db = try await provider.load()
        // kelimeler.txt has ~5608 five-letter words
        XCTAssertGreaterThan(db.targetWords.count, 100, "Should have at least 100 target words")
    }
}
