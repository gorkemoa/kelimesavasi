import SwiftUI
import MultipeerConnectivity

// MARK: - App Route
enum AppRoute: Hashable {
    case soloGame
    case nearbyLobby
    case duelGame(targetWord: String?, config: GameConfig, isHost: Bool)
    case stats
    case settings
}

// MARK: - App Router
struct AppRouter: View {
    @Environment(AppEnvironment.self) private var env
    @State private var path = NavigationPath()

    var body: some View {
        NavigationStack(path: $path) {
            HomeView { route in
                path.append(route)
            }
            .navigationDestination(for: AppRoute.self) { route in
                destination(for: route)
            }
        }
    }

    @ViewBuilder
    private func destination(for route: AppRoute) -> some View {
        switch route {
        case .soloGame:
            GameView(mode: .solo)

        case .nearbyLobby:
            NearbyLobbyView { targetWord, config, isHost in
                path.append(AppRoute.duelGame(targetWord: targetWord,
                                              config: config,
                                              isHost: isHost))
            }
            .navigationBarBackButtonHidden(true)

        case .duelGame(let word, let config, let isHost):
            GameView(mode: .duel, targetWord: word, config: config, isHost: isHost)
        case .stats:
            StatsView()

        case .settings:
            SettingsView()
        }
    }
}
