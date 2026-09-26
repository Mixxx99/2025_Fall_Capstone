import SwiftUI

/// Login screen: validates 4-digit passcode for returning users
struct LoginView: View {
    let onLogin: () -> Void

    @StateObject private var profile = UserProfileStore.shared
    @State private var digits: [Int] = []
    @State private var shakeOffset: CGFloat = 0
    @State private var errorMessage = ""
    @State private var attempts = 0
    private let length = 4

    var body: some View {
        ZStack {
            SWFBackground()

            VStack(spacing: 20) {
                // Brand bar
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
                    .frame(height: 100)

                // Welcome back text
                VStack(spacing: 6) {
                    Text("Welcome Back!")
                        .font(.title2.bold())
                        .foregroundStyle(Color.swfGoldenYellow)

                    if !profile.userName.isEmpty {
                        Text(profile.userName)
                            .font(.headline)
                            .foregroundStyle(.white)
                    }

                    Text("Enter your 4-digit passcode")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.8))
                }

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<length, id: \.self) { i in
                        Circle()
                            .fill(i < digits.count ? Color.swfGoldenYellow : .white.opacity(0.3))
                            .frame(width: 18, height: 18)
                    }
                }
                .offset(x: shakeOffset)

                // Error message
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .transition(.opacity)
                }

                // Keypad
                VStack(spacing: 14) {
                    keyRow([1, 2, 3])
                    keyRow([4, 5, 6])
                    keyRow([7, 8, 9])
                    HStack(spacing: 14) {
                        Spacer().frame(width: 64, height: 64)
                        numKey(0) { append(0) }
                        iconKey("delete.left") { backspace() }
                    }
                }

                Spacer(minLength: 0)
            }
            .onChange(of: digits) { _, newValue in
                if newValue.count == length {
                    validatePasscode()
                }
            }
            .animation(.easeInOut, value: digits.count)
        }
    }

    // MARK: - Validation

    private func validatePasscode() {
        let code = digits.map(String.init).joined()
        if profile.validatePasscode(code) {
            profile.isLoggedIn = true
            onLogin()
        } else {
            attempts += 1
            errorMessage = "Incorrect passcode. Try again."
            // Shake animation
            withAnimation(.default) {
                shakeOffset = 10
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.default) { shakeOffset = -10 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                withAnimation(.default) { shakeOffset = 0 }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                digits = []
            }
        }
    }

    // MARK: - Input

    private func append(_ n: Int) {
        if digits.count < length {
            digits.append(n)
            errorMessage = ""
        }
    }

    private func backspace() {
        if !digits.isEmpty { digits.removeLast() }
    }

    // MARK: - Subviews

    @ViewBuilder private func keyRow(_ nums: [Int]) -> some View {
        HStack(spacing: 14) {
            ForEach(nums, id: \.self) { n in numKey(n) { append(n) } }
        }
    }

    @ViewBuilder private func numKey(_ num: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white.opacity(0.25))
                Text("\(num)")
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder private func iconKey(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack {
                Circle().fill(Color.white.opacity(0.25))
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.white)
            }
            .frame(width: 64, height: 64)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Preview

#Preview {
    LoginView(onLogin: { })
}
