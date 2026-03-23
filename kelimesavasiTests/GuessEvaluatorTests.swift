import XCTest
@testable import kelimesavasi

// MARK: - GuessEvaluator Tests
final class GuessEvaluatorTests: XCTestCase {

    private var sut: GuessEvaluator!

    override func setUp() {
        super.setUp()
        sut = GuessEvaluator()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - Basic evaluation

    func test_allCorrect() {
        let result = sut.evaluate(guess: "kitap", target: "kitap")
        XCTAssertEqual(result, [.correct, .correct, .correct, .correct, .correct])
    }

    func test_allAbsent() {
        let result = sut.evaluate(guess: "bbbbb", target: "aaaaa")
        XCTAssertEqual(result, [.absent, .absent, .absent, .absent, .absent])
    }

    func test_allPresent() {
        // Each letter is in the word but wrong position
        let result = sut.evaluate(guess: "tapki", target: "kitap")
        // t→present, a→present, p→present, k→present, i→present
        XCTAssertEqual(result, [.present, .present, .present, .present, .present])
    }

    func test_mixedStates() {
        // target: "kitap" = k,i,t,a,p
        // guess:  "kilis" = k,i,l,i,s
        let result = sut.evaluate(guess: "kilis", target: "kitap")
        XCTAssertEqual(result[0], .correct)  // k correct
        XCTAssertEqual(result[1], .correct)  // i correct
        XCTAssertEqual(result[2], .absent)   // l not in word
        XCTAssertEqual(result[3], .absent)   // second i — already consumed
        XCTAssertEqual(result[4], .absent)   // s not in word
    }

    // MARK: - Duplicate letter handling

    func test_duplicateInGuess_onlyOneCorrect() {
        // target: "kitap" — one 'a'
        // guess:  "aaaal"
        let result = sut.evaluate(guess: "aaaal", target: "kitap")
        // Only one 'a' should be marked (correct or present), rest absent
        let nonAbsent = result.filter { $0 != .absent }
        XCTAssertEqual(nonAbsent.count, 1)
    }

    func test_duplicateInTarget_bothMarked() {
        // target: "llama" — two l's
        // guess:  "llbcd"
        let result = sut.evaluate(guess: "llbcd", target: "llama")
        XCTAssertEqual(result[0], .correct)   // first l correct
        XCTAssertEqual(result[1], .correct)   // second l correct
        XCTAssertEqual(result[2], .absent)
        XCTAssertEqual(result[3], .absent)
        XCTAssertEqual(result[4], .absent)
    }

    func test_duplicateGuess_targetHasOne_correctTakesPriority() {
        // target: "abcde" — one 'a' at position 0
        // guess:  "aaxyz"
        let result = sut.evaluate(guess: "aaxyz", target: "abcde")
        XCTAssertEqual(result[0], .correct)  // 'a' at pos 0 — correct
        XCTAssertEqual(result[1], .absent)   // second 'a' — target 'a' already consumed
    }

    func test_presentBeforeCorrect_correctTakesPriority() {
        // target: "aabbc"
        // guess:  "aaxyz"
        let result = sut.evaluate(guess: "aaxyz", target: "aabbc")
        XCTAssertEqual(result[0], .correct)  // 'a' correct
        XCTAssertEqual(result[1], .correct)  // 'a' correct (second target a)
    }

    // MARK: - Turkish characters

    func test_turkishCharsCorrect() {
        let result = sut.evaluate(guess: "şeker", target: "şeker")
        XCTAssertEqual(result, [.correct, .correct, .correct, .correct, .correct])
    }

    func test_turkishCharsPresent() {
        // target: "güneş" — ğ,ü,n,e,ş
        // guess:  "şüngö" — ş,ü,n,g,ö
        let result = sut.evaluate(guess: "şüngö", target: "güneş")
        XCTAssertEqual(result[0], .present)  // ş present
        XCTAssertEqual(result[1], .correct)  // ü correct
        XCTAssertEqual(result[2], .correct)  // n correct
        XCTAssertEqual(result[3], .absent)   // g at pos 3 — but g is at pos 0 in target, so present? No: g in target at pos 0, not at pos 3 → present
        // Let me recalculate: target=güneş g(0)ü(1)n(2)e(3)ş(4), guess=şüngö ş(0)ü(1)n(2)g(3)ö(4)
        // Pass 1: pos1 ü==ü correct, pos2 n==n correct
        // Pass 2: pos0 ş→ in target? ş at target[4] → present. pos3 g→ in target? g at target[0] → present. pos4 ö→ not in target → absent
        XCTAssertEqual(result[3], .present)
        XCTAssertEqual(result[4], .absent)
    }

    func test_differentCase_evaluatesEqual() {
        // Evaluation should be case insensitive
        let lowerResult = sut.evaluate(guess: "kitap", target: "KITAP")
        let upperResult = sut.evaluate(guess: "KITAP", target: "kitap")
        XCTAssertEqual(lowerResult, [.correct, .correct, .correct, .correct, .correct])
        XCTAssertEqual(upperResult, [.correct, .correct, .correct, .correct, .correct])
    }
}
