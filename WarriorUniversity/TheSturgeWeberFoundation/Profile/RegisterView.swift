import SwiftUI

/// Account creation: name + email + 4-digit passcode
struct RegisterView: View {
    let onComplete: () -> Void

    @State private var name = ""
    @State private var email = ""
    @State private var step: RegisterStep = .info
    @State private var digits: [Int] = []
    @State private var confirmDigits: [Int] = []
    @State private var isConfirming = false
    @State private var errorMessage = ""
    private let length = 4

    enum RegisterStep {
        case info
        case passcode
    }

    var body: some View {
        ZStack {
            // Solid dark SWF-green background so form fields are readable.
            // Replaced the photo background here because the photo was
            // making input text invisible.
            Color(red: 0.03, green: 0.21, blue: 0.20)
                .ignoresSafeArea()

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

                switch step {
                case .info:
                    infoStep
                case .passcode:
                    passcodeStep
                }

                Spacer(minLength: 0)
            }
            .animation(.easeInOut, value: step)
        }
    }

    // MARK: - Step 1: Name + Email

    private var infoStep: some View {
        VStack(spacing: 20) {
            Text("Create Your Account")
                .font(.title2.bold())
                .foregroundStyle(Color.swfGoldenYellow)

            Text("Tell us a bit about yourself")
                .font(.subheadline)
                .foregroundStyle(.white)

            VStack(spacing: 14) {
                // Name field
                VStack(alignment: .leading, spacing: 6) {
                    Text("YOUR NAME")
                        .font(.caption.bold())
                        .foregroundStyle(Color.swfGoldenYellow)

                    HStack(spacing: 10) {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.white)
                            .frame(width: 20)

                        TextField("", text: $name)
                            .foregroundStyle(.white)
                            .tint(Color.swfGoldenYellow)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .submitLabel(.next)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.swfGoldenYellow, lineWidth: 1.5)
                    )
                }

                // Email field
                VStack(alignment: .leading, spacing: 6) {
                    Text("EMAIL (OPTIONAL)")
                        .font(.caption.bold())
                        .foregroundStyle(Color.swfGoldenYellow)

                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(.white)
                            .frame(width: 20)

                        TextField("", text: $email)
                            .foregroundStyle(.white)
                            .tint(Color.swfGoldenYellow)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                            .submitLabel(.done)
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.15))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.swfGoldenYellow, lineWidth: 1.5)
                    )
                }
            }
            .padding(.horizontal, 24)

            Button {
                withAnimation { step = .passcode }
            } label: {
                Text("Next: Set Passcode")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(name.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray.opacity(0.3) : Color.swfPortWine)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
                    .shadow(radius: 3)
            }
            .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            .padding(.horizontal, 32)
            .padding(.top, 8)
        }
    }

    // MARK: - Step 2: Passcode

    private var passcodeStep: some View {
        VStack(spacing: 16) {
            Text(isConfirming ? "Confirm Passcode" : "Create Passcode")
                .font(.title2.bold())
                .foregroundStyle(Color.swfGoldenYellow)

            Text(isConfirming ? "Enter your passcode again" : "Choose a 4-digit passcode")
                .font(.subheadline)
                .foregroundStyle(.white)

            // PIN dots
            HStack(spacing: 16) {
                let currentDigits = isConfirming ? confirmDigits : digits
                ForEach(0..<length, id: \.self) { i in
                    Circle()
                        .fill(i < currentDigits.count ? Color.swfGoldenYellow : .white.opacity(0.3))
                        .frame(width: 18, height: 18)
                }
            }

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
                    // Back button
                    Button {
                        if isConfirming {
                            isConfirming = false
                            confirmDigits = []
                            errorMessage = ""
                        } else {
                            withAnimation { step = .info }
                        }
                    } label: {
                        ZStack {
                            Circle().fill(Color.white.opacity(0.25))
                            Image(systemName: "arrow.left")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .frame(width: 64, height: 64)
                    }
                    .buttonStyle(.plain)

                    numKey(0) { append(0) }
                    iconKey("delete.left") { backspace() }
                }
            }
        }
        .onChange(of: digits) { _, newValue in
            if newValue.count == length && !isConfirming {
                isConfirming = true
            }
        }
        .onChange(of: confirmDigits) { _, newValue in
            if newValue.count == length && isConfirming {
                finishRegistration()
            }
        }
        .animation(.easeInOut, value: isConfirming)
    }

    // MARK: - Registration

    private func finishRegistration() {
        let passcode = digits.map(String.init).joined()
        let confirm = confirmDigits.map(String.init).joined()

        guard passcode == confirm else {
            errorMessage = "Passcodes don't match. Try again."
            confirmDigits = []
            isConfirming = false
            digits = []
            return
        }

        UserProfileStore.shared.createAccount(
            name: name.trimmingCharacters(in: .whitespaces),
            email: email.trimmingCharacters(in: .whitespaces),
            passcode: passcode
        )
        onComplete()
    }

    // MARK: - Input

    private func append(_ n: Int) {
        if isConfirming {
            if confirmDigits.count < length { confirmDigits.append(n) }
        } else {
            if digits.count < length { digits.append(n) }
        }
        errorMessage = ""
    }

    private func backspace() {
        if isConfirming {
            if !confirmDigits.isEmpty { confirmDigits.removeLast() }
        } else {
            if !digits.isEmpty { digits.removeLast() }
        }
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

#Preview {
    RegisterView(onComplete: { })
}
