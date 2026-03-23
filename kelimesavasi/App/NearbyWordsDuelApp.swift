import SwiftUI

@main
struct NearbyWordsDuelApp: App {
    @State private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            AppRouter()
                .environment(environment)
                .preferredColorScheme(.dark)
        }
    }
}
