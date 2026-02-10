import SwiftUI

struct WelcomeView: View {
    var onContinue: () -> Void

    var body: some View {
        ZStack {
            SWFBackground()  // 🌄 background

            VStack(spacing: 24) {
                // Top brand bar (Green / Golden Yellow / Port Wine)
                HStack(spacing: 0) {
                    Color(red: 0x08/255, green: 0x35/255, blue: 0x33/255) // swfGreen
                    Color(red: 0xeb/255, green: 0xb5/255, blue: 0x33/255) // swfGoldenYellow
                    Color(red: 0x8c/255, green: 0x1e/255, blue: 0x41/255) // swfPortWine
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
                    section(title: "Our Mission", text: "Care, Research, Education, Support")
                }
                .padding(.horizontal, 20)

                Button(action: onContinue) {
                    Text("Continue")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color(red: 0x8c/255, green: 0x1e/255, blue: 0x41/255)) // swfPortWine
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 3)
                }
                .padding(.horizontal, 32)
                .padding(.top, 8)

                Link("Learn more about the foundation here",
                     destination: URL(string: "https://sturge-weber.org")!)
                    .font(.footnote)
                    .foregroundColor(Color(red: 0xeb/255, green: 0xb5/255, blue: 0x33/255)) // swfGoldenYellow

                Spacer(minLength: 0)
            }
        }
    }

    private func section(title: String, text: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.title2.bold())
                .foregroundColor(Color(red: 0xeb/255, green: 0xb5/255, blue: 0x33/255)) // swfGoldenYellow
            Text(text)
                .font(.body)
                .foregroundColor(.white)
        }
    }
}
