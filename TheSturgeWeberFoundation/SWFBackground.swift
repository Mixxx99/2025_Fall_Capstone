import SwiftUI

/// Reusable background using the official group photo.
struct SWFBackground: View {
    var body: some View {
        Image("swf_bg")
            .resizable()
            .scaledToFill()
            .ignoresSafeArea()
            .overlay(
                Color.black.opacity(0.45) // was 0.25 → more contrast for text
            )
    }
}
