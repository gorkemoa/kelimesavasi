import SwiftUI

enum AppTheme {
    // MARK: - Colors
    enum Colors {
        static let background     = Color(hex: "080B12")
        static let surface        = Color(hex: "131720")
        static let surfaceHigh    = Color(hex: "1E2231")
        static let border         = Color(hex: "2E3348")
        static let primary        = Color(hex: "6C8EF5")
        static let primaryDim     = Color(hex: "3D5199")
        static let primaryBright  = Color(hex: "8AAEFF")
        static let text           = Color.white
        static let textSecondary  = Color(hex: "8A8A9A")
        static let textDisabled   = Color(hex: "45455A")

        // Tile states
        static let correct = Color(hex: "538D4E")
        static let present = Color(hex: "B59F3B")
        static let absent  = Color(hex: "3A3A4C")
        static let filled  = Color(hex: "1E2231")
        static let empty   = Color.clear

        // Status
        static let success = Color(hex: "34C759")
        static let warning = Color(hex: "FF9F0A")
        static let error   = Color(hex: "FF453A")
        static let info    = Color(hex: "64D2FF")
        static let gold    = Color(hex: "FFD700")

        // Keyboard
        static let keyDefault  = Color(hex: "252836")
        static let keyEnter    = Color(hex: "3D5199")
        static let keyDelete   = Color(hex: "252836")
    }

    // MARK: - Gradients
    enum Gradients {
        static var primaryButton: LinearGradient {
            LinearGradient(
                colors: [Color(hex: "6C8EF5"), Color(hex: "4A6ADB")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        static var winCelebration: LinearGradient {
            LinearGradient(
                colors: [Color(hex: "538D4E"), Color(hex: "2E6B2A")],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
        static var backgroundTop: RadialGradient {
            RadialGradient(
                colors: [Color(hex: "6C8EF5").opacity(0.15), Color.clear],
                center: .init(x: 0.5, y: 0.0), startRadius: 0, endRadius: 320
            )
        }
    }

    // MARK: - Typography
    enum Font {
        static func tile(_ size: CGFloat = 28) -> SwiftUI.Font { .system(size: size, weight: .bold) }
        static func keyLabel(_ size: CGFloat = 14) -> SwiftUI.Font { .system(size: size, weight: .semibold) }
        static func title(_ size: CGFloat = 28) -> SwiftUI.Font { .system(size: size, weight: .black, design: .rounded) }
        static func headline(_ size: CGFloat = 18) -> SwiftUI.Font { .system(size: size, weight: .semibold) }
        static func body(_ size: CGFloat = 16) -> SwiftUI.Font { .system(size: size, weight: .regular) }
        static func caption(_ size: CGFloat = 12) -> SwiftUI.Font { .system(size: size, weight: .medium) }
    }

    // MARK: - Spacing
    enum Spacing {
        static let xxs: CGFloat = 4
        static let xs: CGFloat  = 8
        static let sm: CGFloat  = 12
        static let md: CGFloat  = 16
        static let lg: CGFloat  = 24
        static let xl: CGFloat  = 32
        static let xxl: CGFloat = 48
    }

    // MARK: - Corner Radius
    enum Radius {
        static let sm: CGFloat  = 6
        static let md: CGFloat  = 10
        static let lg: CGFloat  = 16
        static let xl: CGFloat  = 24
        static let pill: CGFloat = 100
    }
}

// MARK: - Color hex init
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3:
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(.sRGB,
                  red: Double(r) / 255,
                  green: Double(g) / 255,
                  blue: Double(b) / 255,
                  opacity: Double(a) / 255)
    }
}

// MARK: - Surface modifier
struct SurfaceModifier: ViewModifier {
    let elevated: Bool
    func body(content: Content) -> some View {
        content
            .background(elevated ? AppTheme.Colors.surfaceHigh : AppTheme.Colors.surface)
            .cornerRadius(AppTheme.Radius.lg)
    }
}

extension View {
    func surfaceStyle(elevated: Bool = false) -> some View {
        modifier(SurfaceModifier(elevated: elevated))
    }
}
