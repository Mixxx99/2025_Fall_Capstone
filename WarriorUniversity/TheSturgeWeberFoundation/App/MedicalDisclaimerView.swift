//
//  MedicalDisclaimerView.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 4/22/26.
//

import SwiftUI

/// First-launch medical disclaimer. Shown once per device, before any other
/// screen. User must acknowledge before proceeding. Required for App Store
/// review of medical-adjacent apps.
struct MedicalDisclaimerView: View {
    let onAcknowledge: () -> Void

    var body: some View {
        ZStack {
            // Solid dark background so text stays readable
            Color(red: 0.05, green: 0.15, blue: 0.20)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // Brand bar
                HStack(spacing: 0) {
                    Color.swfGreen
                    Color.swfGoldenYellow
                    Color.swfPortWine
                }
                .frame(height: 44)
                .ignoresSafeArea(edges: .top)

                Spacer(minLength: 20)

                // Icon
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(Color.swfGoldenYellow)

                // Heading
                Text("Important Notice")
                    .font(.title.bold())
                    .foregroundStyle(Color.swfGoldenYellow)

                // Body text
                VStack(alignment: .leading, spacing: 16) {
                    Text("Warrior University is a tracking and educational tool created by The Sturge-Weber Foundation to help caregivers and individuals organize medical information.")
                        .foregroundStyle(.white)

                    Text("This app is not a medical device. It does not provide medical advice, diagnosis, or treatment.")
                        .foregroundStyle(.white)
                        .fontWeight(.semibold)

                    Text("Always consult your doctor or qualified healthcare provider for any questions about a medical condition. In case of a medical emergency, call 911 or your local emergency number immediately.")
                        .foregroundStyle(.white)
                }
                .font(.body)
                .padding(.horizontal, 28)
                .multilineTextAlignment(.leading)

                Spacer()

                // Acknowledge button
                Button {
                    // Remember that this user has acknowledged.
                    UserDefaults.standard.set(true, forKey: "wu.disclaimer.acknowledged")
                    onAcknowledge()
                } label: {
                    Text("I Understand")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.swfPortWine)
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .shadow(radius: 3)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
    }

    /// Whether this device has already shown and acknowledged the disclaimer.
    static var hasBeenAcknowledged: Bool {
        UserDefaults.standard.bool(forKey: "wu.disclaimer.acknowledged")
    }
}

#Preview {
    MedicalDisclaimerView(onAcknowledge: { })
}
