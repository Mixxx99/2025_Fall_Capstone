import SwiftUI

// MARK: - Reusable Tile Model
struct HomeTile: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let destination: AnyView
}

// MARK: - Main Home View
struct HomeView: View {
    @State private var username: String = "John Doe"

    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ZStack {
            // Brand gradient background (from BrandKit.swift)
            SWFAppBackground()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    grid
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Warrior University")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    print("Logout tapped")
                } label: {
                    Label("Logout", systemImage: "rectangle.portrait.and.arrow.right")
                }
                .foregroundStyle(.white)
            }
        }
    }

    // MARK: - Header
    private var header: some View {
        ZStack(alignment: .leading) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.swfGreen.opacity(0.95))
                .shadow(color: .black.opacity(0.25), radius: 8, y: 3)

            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.95))
                Text(username)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Your care, learning, and tools — all in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.95))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome, \(username)")
    }

    // MARK: - Grid of Tiles
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(tiles) { tile in
                NavigationLink(destination: tile.destination) {
                    TileView(title: tile.title, systemImage: tile.systemImage)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tiles
    private var tiles: [HomeTile] {
        [
            HomeTile(
                title: "Calendar",
                systemImage: "calendar",
                destination: AnyView(CalendarRootView())
            ),
            HomeTile(
                title: "Notes",
                systemImage: "note.text",
                destination: AnyView(NotesListView())
            ),
            HomeTile(
                title: "Meds & Equipment",
                systemImage: "cross.case",
                destination: AnyView(Text("Meds & Equipment Coming Soon").padding())
            ),
            HomeTile(
                title: "Doctor Info",
                systemImage: "stethoscope",
                destination: AnyView(DoctorListView()) // ✅ updated here
            ),
            HomeTile(
                title: "Analytics",
                systemImage: "chart.bar",
                destination: AnyView(Text("Analytics Coming Soon").padding())
            ),
            HomeTile(
                title: "Articles & Videos",
                systemImage: "book.pages",
                destination: AnyView(Text("Articles & Videos Coming Soon").padding())
            ),
            HomeTile(
                title: "Timer",
                systemImage: "timer",
                destination: AnyView(Text("Timer Coming Soon").padding())
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
    }
}
