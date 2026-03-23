import SwiftUI

struct TileView: View {
    let letter: String
    let state: TileState
    let size: CGFloat
    let isRevealing: Bool
    let revealDelay: Double

    @State private var flipped = false

    private var backgroundColor: Color {
        switch state {
        case .correct: return AppTheme.Colors.correct
        case .present: return AppTheme.Colors.present
        case .absent:  return AppTheme.Colors.absent
        case .filled:  return AppTheme.Colors.filled
        case .empty:   return AppTheme.Colors.empty
        }
    }

    private var borderColor: Color {
        switch state {
        case .empty:  return AppTheme.Colors.border
        case .filled: return Color.white.opacity(0.4)
        default:      return .clear
        }
    }

    private var showResultColor: Bool {
        state == .correct || state == .present || state == .absent
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                .fill(flipped || showResultColor ? backgroundColor : (state == .empty ? AppTheme.Colors.empty : AppTheme.Colors.filled))
                .overlay(
                    RoundedRectangle(cornerRadius: AppTheme.Radius.sm)
                        .stroke(borderColor, lineWidth: 2)
                )

            Text(letter.uppercased())
                .font(AppTheme.Font.tile(size * 0.45))
                .foregroundStyle(AppTheme.Colors.text)
                .scaleEffect(state == .filled && !letter.isEmpty ? 1.08 : 1.0)
                .animation(.spring(response: 0.1, dampingFraction: 0.5), value: letter)
        }
        .frame(width: size, height: size)
        .rotation3DEffect(
            .degrees(flipped || showResultColor ? 0 : (isRevealing ? -90 : 0)),
            axis: (x: 1, y: 0, z: 0)
        )
        .onChange(of: isRevealing) { newValue in
            if newValue {
                DispatchQueue.main.asyncAfter(deadline: .now() + revealDelay) {
                    withAnimation(.easeInOut(duration: AppConstants.guessAnimationDuration)) {
                        flipped = true
                    }
                }
            }
        }
        .onChange(of: state) { new in
            if new == .correct || new == .present || new == .absent {
                // If state changes directly (e.g. initial load), ensure it's flipped
                flipped = true
            }
        }
    }
}

#Preview {
    HStack(spacing: 6) {
        TileView(letter: "K", state: .correct, size: 56, isRevealing: false, revealDelay: 0)
        TileView(letter: "E", state: .present, size: 56, isRevealing: false, revealDelay: 0)
        TileView(letter: "L", state: .absent,  size: 56, isRevealing: false, revealDelay: 0)
        TileView(letter: "M", state: .filled,  size: 56, isRevealing: false, revealDelay: 0)
        TileView(letter: "",  state: .empty,   size: 56, isRevealing: false, revealDelay: 0)
    }
    .padding()
    .background(AppTheme.Colors.background)
}
