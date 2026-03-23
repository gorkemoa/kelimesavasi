import SwiftUI

@main
struct NearbyWordsDuelApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environmentObject(environment)
                .preferredColorScheme(.dark)
        }
    }
}
