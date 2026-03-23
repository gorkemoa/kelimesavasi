import SwiftUI

struct GameBoardView: View {
    let viewModel: GameViewModel

    private var wordLength: Int { viewModel.session.config.wordLength }
    private var maxGuesses: Int { viewModel.session.config.maxGuesses }

    // Tile size adapts to screen
    private var tileSize: CGFloat {
        let screenWidth = UIScreen.main.bounds.width
        let spacing: CGFloat = 6
        let totalSpacing = spacing * CGFloat(wordLength - 1) + 32
        let raw = (screenWidth - totalSpacing) / CGFloat(wordLength)
        return min(raw, 64)
    }

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<maxGuesses, id: \.self) { row in
                rowView(for: row)
            }
        }
        .padding(.horizontal, 16)
    }

    @ViewBuilder
    private func rowView(for row: Int) -> some View {
        let isShaking   = viewModel.shakingRow == row
        let isRevealing = viewModel.revealingRow == row

        HStack(spacing: 6) {
            ForEach(0..<wordLength, id: \.self) { col in
                let letter = viewModel.tileLetter(row: row, col: col)
                let state  = viewModel.tileState(row: row, col: col)
                let delay  = Double(col) * AppConstants.flipAnimationDelay

                TileView(letter: letter,
                         state: state,
                         size: tileSize,
                         isRevealing: isRevealing,
                         revealDelay: delay)
            }
        }
        .modifier(ShakeModifier(shaking: isShaking))
    }
}

// MARK: - Shake modifier
struct ShakeModifier: ViewModifier {
    let shaking: Bool
    @State private var offset: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .offset(x: offset)
            .onChange(of: shaking) { _, isShaking in
                guard isShaking else { return }
                withAnimation(.default.repeatCount(5, autoreverses: true).speed(4)) {
                    offset = 8
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { offset = 0 }
            }
    }
}

#Preview {
    let session = GameSession(mode: .solo, config: .default, targetWord: "kitap")
    let repo    = WordRepository()
    let engine  = WordleGameEngine(wordRepository: repo)
    let settings = SettingsService()
    let stats   = StatsService()
    let vm = GameViewModel(session: session, engine: engine, settings: settings, stats: stats)
    GameBoardView(viewModel: vm)
        .background(AppTheme.Colors.background)
}
