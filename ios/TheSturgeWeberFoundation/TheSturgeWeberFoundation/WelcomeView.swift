import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            // Brand bar (forest green / yellow / maroon)
            HStack(spacing: 0) {
                Color(red: 0x0b/255, green: 0x35/255, blue: 0x33/255)
                Color.yellow
                Color(red: 0x8A/255, green: 0x0B/255, blue: 0x0B/255)
            }
            .frame(height: 44)
            .ignoresSafeArea(edges: .top)

            // Logo (add to Assets.xcassets as "swf_logo")
            Image("swf_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 140)
                .accessibilityLabel("The Sturge-Weber Foundation")

            VStack(spacing: 20) {
                section(title: "Our Mission", text: "Mission here")
                section(title: "Our Vision", text: "Vision here")
                section(title: "What this app is", text: "App stated here")
            }
            .padding(.horizontal, 20)

            Button(action: onContinue) {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color(red: 0x0b/255, green: 0x35/255, blue: 0x33/255))
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .padding(.top, 8)

            Link("Learn more about the foundation here",
                 destination: URL(string: "https://sturge-weber.org")!)
                .font(.footnote)
                .padding(.top, 8)

            Spacer(minLength: 0)
        }
    }

    private func section(title: String, text: String) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.title2).bold().foregroundStyle(.secondary)
            Text(text).font(.body).foregroundStyle(.secondary)
        }
    }
}
