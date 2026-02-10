//
//  EventDetailView.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import SwiftUI

struct EventDetailView: View {
    let event: EventEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.title ?? "")
                    .font(.largeTitle).bold()
                Text(event.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .padding(.top, 4)
                }
                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Event Details")
    }
}
