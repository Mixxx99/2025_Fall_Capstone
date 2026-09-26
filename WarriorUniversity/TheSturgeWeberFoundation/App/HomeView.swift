import SwiftUI

// MARK: - Reusable Tile Model
struct HomeTile: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let destination: AnyView
}

// MARK: - Home Sections (Karen's Care / Engage / Learn / Research grouping)
struct HomeSection: Identifiable {
    var id: String { title }
    let title: String
    let subtitle: String
    let tiles: [HomeTile]
}

// MARK: - Main Home View
struct HomeView: View {
    @StateObject private var profile = UserProfileStore.shared
    @State private var showLogoutAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            // More transparent gradient background
            LinearGradient(
                colors: [
                    Color.swfGreen.opacity(0.75),
                    Color.swfPortWine.opacity(0.75)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    header
                    ForEach(sections) { section in
                        sectionView(section)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Warrior University")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen.opacity(0.95), for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showLogoutAlert = true
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .foregroundStyle(.white)
            }
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                profile.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
    }

    // MARK: - Header
    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.swfGreen.opacity(0.85))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.95))
                Text(profile.userName.isEmpty ? "Warrior" : profile.userName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("A lifeline for learning")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.95))
                    .minimumScaleFactor(0.7)
                    .lineLimit(2)
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome, \(profile.userName)")
    }

    // MARK: - Section
    private func sectionView(_ section: HomeSection) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(section.title)
                    .font(.title3.bold())
                    .foregroundStyle(.white)
                Text(section.subtitle)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .accessibilityElement(children: .combine)
            .accessibilityAddTraits(.isHeader)

            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(section.tiles) { tile in
                    NavigationLink(destination: tile.destination) {
                        TileView(title: tile.title, systemImage: tile.systemImage)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - Sections
    // Grouping requested by Karen (May 2026). Existing screens are unchanged;
    // only where they appear on the home screen moved.
    private var sections: [HomeSection] {
        [
            HomeSection(
                title: "Care",
                subtitle: "Day-to-day tools for managing care",
                tiles: [
                    HomeTile(title: "Timer", systemImage: "timer",
                             destination: AnyView(TimerHubView())),
                    HomeTile(title: "Doctor Info", systemImage: "stethoscope",
                             destination: AnyView(DoctorListView())),
                    HomeTile(title: "Meds & Equipment", systemImage: "cross.case",
                             destination: AnyView(MedsEquipmentListView()))
                ]
            ),
            HomeSection(
                title: "Engage",
                subtitle: "Plan, write, and stay organized",
                tiles: [
                    HomeTile(title: "Calendar", systemImage: "calendar",
                             destination: AnyView(CalendarRootView())),
                    HomeTile(title: "Notes", systemImage: "note.text",
                             destination: AnyView(NotesListView())),
                    HomeTile(title: "My Profile", systemImage: "person.crop.circle",
                             destination: AnyView(UserProfileView()))
                ]
            ),
            HomeSection(
                title: "Learn",
                subtitle: "Trusted resources from SWF",
                tiles: [
                    HomeTile(title: "Articles & Videos", systemImage: "book.pages",
                             destination: AnyView(ArticlesVideosView()))
                    // TODO (waiting on Karen): ER Guide tile goes here once its content is approved.
                    // TODO (waiting on Karen): feature the laser/PubMed article inside Articles & Videos.
                ]
            ),
            HomeSection(
                title: "Research",
                subtitle: "See patterns in your own logs",
                tiles: [
                    HomeTile(title: "Analytics", systemImage: "chart.bar",
                             destination: AnyView(AnalyticsView())),
                    HomeTile(title: "Seizure Insights", systemImage: "waveform.path.ecg",
                             destination: AnyView(SeizureInsightsView()))
                    // TODO (waiting on Julia/Karen): Legal & Insurance, if still wanted.
                ]
            )
        ]
    }
}

// MARK: - Tile View (glass card)
struct TileView: View {
    let title: String
    let systemImage: String

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(height: 48)
                Text(title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 8)
            }
            .padding(16)
        }
        .frame(height: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}

// MARK: - Canvas Preview
#Preview {
    NavigationStack {
        HomeView()
            .environmentObject(TimerStore.shared) // For Timer screens to work in preview
    }
}
