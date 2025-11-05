import SwiftUI

struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: EventStore

    @State private var title = ""
    @State private var notes = ""
    @State private var date: Date

    // NEW: tag fields
    @State private var tagTitle: String = ""
    @State private var tagColor: Color = Color(hex: "EBB533") ?? .yellow   // SWF golden yellow

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

                // NEW: Tag section
                Section("Tag (optional)") {
                    TextField("Tag title (e.g., Neurology)", text: $tagTitle)
                    ColorPicker("Tag color", selection: $tagColor, supportsOpacity: false)
                }
            }
            .navigationTitle("New Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        store.addEvent(
                            title: trimmed,
                            date: date,
                            notes: notes.isEmpty ? nil : notes,
                            tagTitle: tagTitle.isEmpty ? nil : tagTitle,
                            tagColorHex: tagTitle.isEmpty ? nil : tagColor.hex6
                        )
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
