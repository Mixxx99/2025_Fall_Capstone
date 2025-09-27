import SwiftUI

struct PasscodeSetupView: View {
    let onComplete: () -> Void

    @State private var digits: [Int] = []
    @State private var didFinish = false
    private let length = 4

    var body: some View {
        VStack(spacing: 24) {
            // Brand bar
            HStack(spacing: 0) {
                Color(red: 0x0b/255, green: 0x35/255, blue: 0x33/255)
                Color.yellow
                Color(red: 0x8A/255, green: 0x0B/255, blue: 0x0B/255)
            }
            .frame(height: 44)
            .ignoresSafeArea(edges: .top)

            // Logo
            Image("swf_logo")
                .resizable()
                .scaledToFit()
                .frame(height: 120)
                .padding(.top, 12)

            // PIN dots
            HStack(spacing: 16) {
                ForEach(0..<length, id: \.self) { i in
                    Circle()
                        .fill(i < digits.count ? .gray : .gray.opacity(0.25))
                        .frame(width: 18, height: 18)
                        .accessibilityHidden(true)
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
                    .background(Color(red: 0x0b/255, green: 0x35/255, blue: 0x33/255))
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            .padding(.horizontal, 32)
            .disabled(digits.count != length)
            .opacity(digits.count == length ? 1 : 0.6)

            Link("Learn more about the foundation here",
                 destination: URL(string: "https://sturge-weber.org")!)
                .font(.footnote)

            Spacer(minLength: 0)
        }
        .onChange(of: digits) { _, newValue in
            if newValue.count == length { finish() }
        }
        .animation(.easeInOut, value: digits.count)
    }

    // MARK: - Helpers
    private func append(_ n: Int) { if digits.count < length { digits.append(n) } }
    private func backspace() { if !digits.isEmpty { digits.removeLast() } }

    private func finish() {
        guard !didFinish, digits.count == length else { return }
        didFinish = true
        let code = digits.map(String.init).joined()
        // Demo storage; move to Keychain for production
        UserDefaults.standard.set(code, forKey: "wu.passcode")

        // Navigate on next runloop to avoid state-during-update crash
        DispatchQueue.main.async { onComplete() }
    }

    // MARK: - Subviews
    @ViewBuilder private func row(_ nums: [Int]) -> some View {
        HStack(spacing: 14) { ForEach(nums, id: \.self) { n in key(num: n) { append(n) } } }
    }
    @ViewBuilder private func key(num: Int, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack { Circle().fill(Color.gray.opacity(0.2)); Text("\(num)").font(.title2).bold().foregroundStyle(.secondary) }
                .frame(width: 64, height: 64)
        }.buttonStyle(.plain)
    }
    @ViewBuilder private func key(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            ZStack { Circle().fill(Color.gray.opacity(0.2)); Image(systemName: icon).font(.title3).foregroundStyle(.secondary) }
                .frame(width: 64, height: 64)
        }.buttonStyle(.plain)
    }
}
