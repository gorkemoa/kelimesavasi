import XCTest
@testable import kelimesavasi

// MARK: - GameViewModel tile display tests
// Verifies tileLetter / tileState correctly handle revealed hints and currentInput mapping.
final class GameViewModelTileTests: XCTestCase {

    private var repo: WordRepository!
    private var engine: WordleGameEngine!
    private var settings: SettingsService!
    private var stats: StatsService!

    override func setUp() {
        super.setUp()
        repo     = WordRepository()
        engine   = WordleGameEngine(wordRepository: repo)
        settings = SettingsService()
        stats    = StatsService()
    }

    // MARK: - Helpers

    private func makeVM(target: String) -> GameViewModel {
        let session = GameSession(mode: .solo, config: .default, targetWord: target)
        return GameViewModel(session: session, engine: engine, settings: settings, stats: stats)
    }

    // MARK: - tileLetter — no hints

    func test_tileLetter_noHints_emptyInput_allEmpty() {
        let vm = makeVM(target: "kitap")
        let activeRow = 0  // no guesses yet
        for col in 0..<5 {
            XCTAssertEqual(vm.tileLetter(row: activeRow, col: col), "")
        }
    }

    func test_tileLetter_noHints_inputFillsLeftToRight() {
        let vm = makeVM(target: "kitap")
        vm.addLetter("a")
        vm.addLetter("b")
        // Active row is row 0
        XCTAssertEqual(vm.tileLetter(row: 0, col: 0), "a")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 1), "b")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 2), "")
    }

    // MARK: - tileLetter — with hints

    func test_tileLetter_hintAtCol0_inputShiftedRight() {
        let vm = makeVM(target: "kitap")
        // Manually inject a hint at column 0
        vm._testing_setHint("k", at: 0)
        vm.addLetter("a")  // should appear at col 1
        vm.addLetter("b")  // should appear at col 2

        XCTAssertEqual(vm.tileLetter(row: 0, col: 0), "k", "Hint appears at col 0")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 1), "a", "Input[0] maps to first non-hint col (1)")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 2), "b", "Input[1] maps to second non-hint col (2)")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 3), "")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 4), "")
    }

    func test_tileLetter_hintAtMiddleCol_inputFillsAroundHint() {
        let vm = makeVM(target: "kitap")
        // Hint at col 2
        vm._testing_setHint("t", at: 2)
        vm.addLetter("x")  // col 0 (non-hint index 0)
        vm.addLetter("y")  // col 1 (non-hint index 1)
        vm.addLetter("z")  // col 3 (non-hint index 2, col 2 is hint)

        XCTAssertEqual(vm.tileLetter(row: 0, col: 0), "x")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 1), "y")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 2), "t", "Hint at col 2")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 3), "z", "Input[2] maps to col 3 (skips hint at col 2)")
        XCTAssertEqual(vm.tileLetter(row: 0, col: 4), "")
    }

    func test_tileLetter_hintAtLastCol_inputFillsFirst4() {
        let vm = makeVM(target: "kitap")
        vm._testing_setHint("p", at: 4)
        vm.addLetter("a")
        vm.addLetter("b")
        vm.addLetter("c")
        vm.addLetter("d")

        for (i, expected) in ["a", "b", "c", "d"].enumerated() {
            XCTAssertEqual(vm.tileLetter(row: 0, col: i), expected)
        }
        XCTAssertEqual(vm.tileLetter(row: 0, col: 4), "p", "Hint at last col")
    }

    // MARK: - tileState — with hints

    func test_tileState_hintAtCol0_inputFilledState() {
        let vm = makeVM(target: "kitap")
        vm._testing_setHint("k", at: 0)
        vm.addLetter("a")

        XCTAssertEqual(vm.tileState(row: 0, col: 0), .correct, "Hint col is .correct")
        XCTAssertEqual(vm.tileState(row: 0, col: 1), .filled,  "Typed char is .filled")
        XCTAssertEqual(vm.tileState(row: 0, col: 2), .empty,   "Untyped col is .empty")
    }

    func test_tileState_hintAtMiddleCol_doNotCountHintAsInput() {
        let vm = makeVM(target: "kitap")
        vm._testing_setHint("t", at: 2)
        vm.addLetter("x")  // maps to col 0
        // col 1 not typed yet

        XCTAssertEqual(vm.tileState(row: 0, col: 0), .filled)
        XCTAssertEqual(vm.tileState(row: 0, col: 1), .empty)
        XCTAssertEqual(vm.tileState(row: 0, col: 2), .correct)
        XCTAssertEqual(vm.tileState(row: 0, col: 3), .empty)
    }

    // MARK: - addLetter respects hint count

    func test_addLetter_stopsAtWordLengthMinusHints() {
        let vm = makeVM(target: "kitap")
        vm._testing_setHint("k", at: 0)
        vm._testing_setHint("i", at: 1)
        // Only 3 more letters allowed

        for letter in ["a", "b", "c", "d", "e"] {
            vm.addLetter(letter)
        }

        XCTAssertEqual(vm.currentInput.count, 3, "Should cap input at wordLen - hintCount")
    }
}

// MARK: - Allow test access to session.revealedHints
// GameSession.revealedHints is var so direct mutation works in tests.
