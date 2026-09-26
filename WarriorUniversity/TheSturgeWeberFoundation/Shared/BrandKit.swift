import SwiftUI

// MARK: - Sturge-Weber Brand Colors (Single source of truth)
public extension Color {
    static let swfPortWine = Color(red: 0x8c/255, green: 0x1e/255, blue: 0x41/255) // deep wine
    static let swfGoldenYellow = Color(red: 0xeb/255, green: 0xb5/255, blue: 0x33/255) // gold
    static let swfGreen = Color(red: 0x08/255, green: 0x35/255, blue: 0x33/255) // dark green
}

// MARK: - Unified Gradient Background
public struct SWFAppBackground: View {
    public init() {}
    public var body: some View {
        LinearGradient(
            colors: [
                Color.swfGreen.opacity(0.95),
                Color.swfPortWine.opacity(0.95)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }
}
