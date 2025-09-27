import SwiftUI

// MARK: - Brand Colors
extension Color {
    /// Forest green from Android project (#0b3533)
    static let wuPrimary = Color(red: 0x0b/255, green: 0x35/255, blue: 0x33/255)
}

// MARK: - Reusable Tile Model
struct HomeTile: Identifiable {
    let id = UUID()
    let title: String
    let systemImage: String
    let background: Color
    let action: () -> Void
}

// MARK: - Home View
struct HomeView: View {
    @State private var username: String = "John Doe" // TODO: bind to real user profile

    // Two-column adaptive grid
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                header
                grid
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 24)
        }
        .background(Color(.systemBackground))
        .navigationTitle("Warrior University")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.wuPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // TODO: Hook up to auth sign-out
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
                .fill(Color.wuPrimary)
            VStack(alignment: .leading, spacing: 6) {
                Text("Welcome")
                    .font(.callout)
                    .foregroundStyle(.white.opacity(0.8))
                Text(username)
                    .font(.title2.bold())
                    .foregroundStyle(.white)
                Text("Your care, learning, and tools — all in one place.")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(16)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Welcome, \(username)")
    }

    // MARK: - Grid of Tiles (mirrors Android home_page.xml)
    private var grid: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(tiles) { tile in
                Button(action: tile.action) {
                    TileView(title: tile.title, systemImage: tile.systemImage, background: tile.background)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Tiles
    private var tiles: [HomeTile] {
        [
            HomeTile(title: "Calendar", systemImage: "calendar", background: .wuPrimary.opacity(0.08)) {
                print("Calendar tapped")
            },
            HomeTile(title: "Notes", systemImage: "note.text", background: .wuPrimary.opacity(0.08)) {
                print("Notes tapped")
            },
            HomeTile(title: "Meds & Equipment", systemImage: "cross.case", background: .wuPrimary.opacity(0.08)) {
                print("Meds & Equipment tapped")
            },
            HomeTile(title: "Doctor Info", systemImage: "stethoscope", background: .wuPrimary.opacity(0.08)) {
                print("Doctor Info tapped")
            },
            HomeTile(title: "Analytics", systemImage: "chart.bar", background: .wuPrimary.opacity(0.08)) {
                print("Analytics tapped")
            },
            HomeTile(title: "Articles & Videos", systemImage: "book.pages", background: .wuPrimary.opacity(0.08)) {
                print("Articles & Videos tapped")
            },
            HomeTile(title: "Timer", systemImage: "timer", background: .wuPrimary.opacity(0.08)) {
                print("Timer tapped")
            }
        ]
    }
}

// MARK: - Tile View
struct TileView: View {
    let title: String
    let systemImage: String
    let background: Color

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(background)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(Color.wuPrimary.opacity(0.15), lineWidth: 1)
                )
            VStack(spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 36, weight: .semibold))
                    .foregroundStyle(Color.wuPrimary)
                    .frame(height: 48)
                Text(title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .foregroundStyle(Color.wuPrimary)
                    .padding(.horizontal, 8)
            }
            .padding(16)
        }
        .frame(height: 140)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(title)
    }
}
