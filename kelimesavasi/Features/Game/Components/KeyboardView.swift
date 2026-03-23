import SwiftUI

// MARK: - Turkish Q keyboard layout
private let keyboardRows: [[String]] = [
    ["e", "r", "t", "y", "u", "ı", "o", "p", "ğ", "ü"],
    ["a", "s", "d", "f", "g", "h", "j", "k", "l", "ş", "i"],
    ["z", "x", "c", "v", "b", "n", "m", "ö", "ç"]
]

struct KeyboardView: View {
    let keyStates: [String: TileState]
    let onLetter: (String) -> Void
    let onDelete: () -> Void
    let onSubmit: () -> Void

    var body: some View {
        VStack(spacing: 6) {
            ForEach(keyboardRows.indices, id: \.self) { rowIndex in
                let row = keyboardRows[rowIndex]
                HStack(spacing: 3) {
                    if rowIndex == 2 {
                        actionKey(label: "ENTER", color: AppTheme.Colors.keyEnter, action: onSubmit)
                            .frame(minWidth: 58)
                    }
                    
                    ForEach(row, id: \.self) { letter in
                        letterKey(letter)
                    }
                    
                    if rowIndex == 2 {
                        actionKey(icon: "delete.left", color: AppTheme.Colors.keyDelete, action: onDelete)
                            .frame(minWidth: 44)
                    }
                }
                .padding(.horizontal, 3)
            }
        }
        .padding(.bottom, 8)
    }

    @ViewBuilder
    private func letterKey(_ letter: String) -> some View {
        let state = keyStates[letter]
        Button {
            onLetter(letter)
        } label: {
            Text(letter.uppercased())
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(AppTheme.Colors.text)
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .background(keyBackground(for: state))
                .cornerRadius(AppTheme.Radius.sm)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func actionKey(label: String? = nil, icon: String? = nil, color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Group {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .bold))
                } else if let label = label {
                    Text(label)
                        .font(.system(size: 13, weight: .bold))
                }
            }
            .foregroundStyle(AppTheme.Colors.text)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(color)
            .cornerRadius(AppTheme.Radius.sm)
        }
        .buttonStyle(.plain)
    }

    private func keyBackground(for state: TileState?) -> Color {
        switch state {
        case .correct: return AppTheme.Colors.correct
        case .present: return AppTheme.Colors.present
        case .absent:  return AppTheme.Colors.absent
        default:       return AppTheme.Colors.keyDefault
        }
    }
}

#Preview {
    KeyboardView(keyStates: ["a": .correct, "e": .present, "r": .absent],
                 onLetter: { _ in }, onDelete: {}, onSubmit: {})
        .background(AppTheme.Colors.background)
}
