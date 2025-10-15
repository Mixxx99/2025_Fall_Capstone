//
//  EditEventView.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: EventStore

    @State private var title = ""
    @State private var notes = ""
    @State private var date: Date

    init(selectedDate: Date) {
        _date = State(initialValue: selectedDate)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date & Time", selection: $date)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addEvent(title: trimmed, date: date, notes: notes.isEmpty ? nil : notes)
                        dismiss()
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
