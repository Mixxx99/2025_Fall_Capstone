import SwiftUI

struct PasscodeSetupView: View {
    let onComplete: () -> Void

    @State private var digits: [Int] = []
    @State private var didFinish = false
    private let length = 4

    var body: some View {
        ZStack {
            SWFBackground()

            VStack(spacing: 24) {
                HStack(spacing: 0) {
                    Color.swfGreen
                    Color.swfGoldenYellow
                    Color.swfPortWine
                }
                .frame(height: 44)
                .ignoresSafeArea(edges: .top)

                Image("swf_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 120)
                    .padding(.top, 12)

                // PIN dots
                HStack(spacing: 16) {
                    ForEach(0..<length, id: \.self) { i in
                        Circle()
                            .fill(i < digits.count ? Color.swfGoldenYellow : .white.opacity(0.3))
                            .frame(width: 18, height: 18)
                    }
                }

                // Keypad
                VStack(spacing: 14) {
                    row([1,2,3])
                    row([4,5,6])
                    row([7,8,9])
                    HStack(spacing: 14) {
                        Spacer().frame(width: 64, height: 64)
                        key(num: 0) { append(0) }
                        key(icon: "delete.left") { backspace() }
                    }
                }

                Button {
                    finish()
                } label: {
                    Text("Click Here To Create An Account!")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.swfPortWine)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 3)
                }
                .padding(.horizontal, 32)
                .disabled(digits.count != length)
                .opacity(digits.count == length ? 1 : 0.6)

                Link("Learn more about the foundation here",
                     destination: URL(string: "https://sturge-weber.org")!)
                    .font(.footnote)
                    .foregroundColor(.swfGoldenYellow)

                Spacer(minLength: 0)
            }
            .onChange(of: digits) { _, newValue in
                if newValue.count == length { finish() }
            }
            .animation(.easeInOut, value: digits.count)
        }
    }

    // MARK: - Helpers
    private func append(_ n: Int) { if digits.count < length { digits.append(n) } }
    private func backspace() { if !digits.isEmpty { digits.removeLast() } }

    private func finish() {
        guard !didFinish, digits.count == length else { return }
        didFinish = true
        let code = digits.map(String.init).joined()
        UserDefaults.standard.set(code, forKey: "wu.passcode")
        DispatchQueue.main.async { onComplete() }
    }

    // MARK: - Subviews
    @ViewBuilder private func row(_ nums: [Int]) -> some View {
        HStack(spacing: 14) {
            ForEach(nums, id: \.self) { n in key(num: n) { append(n) } }
        }
    }

    @ViewBuilder private func key(num: Int, action: @escaping () -> Void) -> some View {
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

    @ViewBuilder private func key(icon: String, action: @escaping () -> Void) -> some View {
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
