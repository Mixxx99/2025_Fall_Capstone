import SwiftUI

@main
struct TheSturgeWeberFoundationApp: App {
    // Shared stores available app-wide
    @StateObject private var eventStore = EventStore.shared
    @StateObject private var timerStore = TimerStore.shared

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environmentObject(eventStore)   // Events (Calendar, etc.)
                .environmentObject(timerStore)   // Timer feature
        }
    }
}

/// Navigation router: Welcome → Passcode → Home
struct RootRouter: View {
    enum Route: Hashable { case passcodeSetup, home }
    @State private var path: [Route] = []

    var body: some View {
        NavigationStack(path: $path) {
            startView
                .navigationDestination(for: Route.self) { route in
                    switch route {
                    case .passcodeSetup:
                        PasscodeSetupView {
                            // push Home on next runloop tick (avoids state-during-update crash)
                            DispatchQueue.main.async { path.append(.home) }
                        }
                    case .home:
                        HomeView()
                    }
                }
        }
        .task {
            // If passcode already set, jump straight to Home on launch
            if UserDefaults.standard.string(forKey: "wu.passcode") != nil {
                path = [.home]
            }
        }
    }

    @ViewBuilder
    private var startView: some View {
        WelcomeView {
            path.append(.passcodeSetup)
        }
    }
}
