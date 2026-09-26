import SwiftUI

@main
struct TheSturgeWeberFoundationApp: App {
    // Shared stores available app-wide
    @StateObject private var eventStore = EventStore.shared
    @StateObject private var timerStore = TimerStore.shared
    @StateObject private var profileStore = UserProfileStore.shared

    var body: some Scene {
        WindowGroup {
            RootRouter()
                .environmentObject(eventStore)
                .environmentObject(timerStore)
                .environmentObject(profileStore)
        }
    }
}

/// Navigation router: Welcome → Register/Login → Home
/// Supports: new users (register), returning users (login), logout
/// Navigation router: Disclaimer → Welcome → Register/Login → Home
/// Supports: new users (register), returning users (login), logout
struct RootRouter: View {
    @EnvironmentObject private var profileStore: UserProfileStore

    enum Route: Hashable { case register, login, home }
    @State private var path: [Route] = []
    @State private var showDisclaimer: Bool = !MedicalDisclaimerView.hasBeenAcknowledged

    var body: some View {
        ZStack {
            NavigationStack(path: $path) {
                startView
                    .navigationDestination(for: Route.self) { route in
                        switch route {
                        case .register:
                            RegisterView {
                                reloadStoresForCurrentUser()
                                DispatchQueue.main.async { path = [.home] }
                            }
                            .navigationBarBackButtonHidden()
                        case .login:
                            LoginView {
                                reloadStoresForCurrentUser()
                                DispatchQueue.main.async { path = [.home] }
                            }
                            .navigationBarBackButtonHidden()
                        case .home:
                            HomeView()
                                .navigationBarBackButtonHidden()
                        }
                    }
            }
            .task {
                determineInitialRoute()
            }
            .onChange(of: profileStore.isLoggedIn) { _, loggedIn in
                if !loggedIn {
                    reloadStoresForCurrentUser()
                    path = []
                }
            }

            // Disclaimer overlays everything on first launch only
            if showDisclaimer {
                MedicalDisclaimerView {
                    withAnimation { showDisclaimer = false }
                }
                .transition(.opacity)
                .zIndex(1)
            }
        }
    }

    @ViewBuilder
    private var startView: some View {
        WelcomeView {
            if profileStore.hasAccount {
                path.append(.login)
            } else {
                path.append(.register)
            }
        }
    }

    private func determineInitialRoute() {
        if profileStore.hasAccount && profileStore.isLoggedIn {
            reloadStoresForCurrentUser()
            path = [.home]
        } else if profileStore.hasAccount {
            path = [.login]
        }
    }

    @MainActor
    private func reloadStoresForCurrentUser() {
        EventStore.shared.fetchEvents()
        DoctorStore.shared.fetch(search: nil)
        NoteStore.shared.fetchNotes()
        MedsEquipmentStore.shared.fetchAll()
        TimerStore.shared.reloadForCurrentUserIfNeeded()
    }
}
