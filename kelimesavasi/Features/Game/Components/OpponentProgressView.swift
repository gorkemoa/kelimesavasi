import SwiftUI

struct OpponentProgressView: View {
    let opponentGuessCount: Int
    let maxGuesses: Int
    let isDone: Bool
    let opponentName: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "person.fill")
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .font(.caption)

            Text(opponentName)
                .font(AppTheme.Font.caption())
                .foregroundStyle(AppTheme.Colors.textSecondary)
                .lineLimit(1)

            Spacer()

            if isDone {
                Text("Tamamladı")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.info)
            } else {
                Text("\(opponentGuessCount)/\(maxGuesses)")
                    .font(AppTheme.Font.caption())
                    .foregroundStyle(AppTheme.Colors.textSecondary)

                ProgressView(value: Double(opponentGuessCount), total: Double(maxGuesses))
                    .tint(AppTheme.Colors.primary)
                    .frame(width: 80)
            }
        }
        .padding(.horizontal, AppTheme.Spacing.md)
        .padding(.vertical, AppTheme.Spacing.xs)
        .background(AppTheme.Colors.surface)
        .cornerRadius(AppTheme.Radius.md)
    }
}

#Preview {
    VStack(spacing: 8) {
        OpponentProgressView(opponentGuessCount: 3, maxGuesses: 6, isDone: false, opponentName: "Ahmet")
        OpponentProgressView(opponentGuessCount: 4, maxGuesses: 6, isDone: true, opponentName: "Zeynep")
    }
    .padding()
    .background(AppTheme.Colors.background)
}
