import SwiftUI

/// Reusable background using the official group photo.
struct SWFBackground: View {
    var body: some View {
        Image("swf_bg")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(
                Color.black.opacity(0.30) // Reduced from 0.45 to 0.30 for more transparency
            )
    }
}
