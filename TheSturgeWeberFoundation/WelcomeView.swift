import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            SWFBackground()  // 🌄 background

            VStack(spacing: 24) {
                // Top brand bar (Green / Golden Yellow / Port Wine)
                HStack(spacing: 0) {
                    Color.swfGreen
                    Color.swfGoldenYellow
                    Color.swfPortWine
                }
                .frame(height: 44)
                .ignoresSafeArea(edges: .top)

                // Logo
                Image("swf_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 140)
                    .accessibilityLabel("The Sturge-Weber Foundation")

                VStack(spacing: 20) {
                    section(title: "Our Mission", text: "To improve the quality of life and care for people with Sturge-Weber syndrome and associated Port-Wine Birthmark conditions through tenacious collaboration with clinical partners and pioneers, education, advocacy, research, and friendly support.")
                    section(title: "Our Vision", text: "Vision here")
                    section(title: "What this app is", text: "App stated here")
                }
                .padding(.horizontal, 20)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.swfPortWine)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 3)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Link("Learn more about the foundation here",
                     destination: URL(string: "https://sturge-weber.org")!)
                    .font(.footnote)
                    .foregroundColor(.swfGoldenYellow)

                Spacer(minLength: 0)
            }
        }
    }

    private func section(title: String, text: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(.swfGoldenYellow)
            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}
