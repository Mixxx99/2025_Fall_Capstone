import SwiftUI

/// A single form that handles BOTH creating a new event AND editing an
/// existing one. Previously this was only a create form that was routed
/// to from everywhere including the "edit" path, so tapping an event and
/// trying to change it silently made a duplicate instead of updating.
///
/// Now:
/// - `EditEventView(selectedDate:)` → create mode (New Event)
/// - `EditEventView(event:)`        → edit mode (pre-fills, updates in place)
struct EditEventView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var store: EventStore

    // Optional existing event. nil = create, non-nil = edit.
    private let existingEvent: EventEntity?

    @State private var title: String
    @State private var notes: String
    @State private var date: Date
    @State private var tagTitle: String
    @State private var tagColor: Color
    @State private var showDeleteConfirm = false

    // MARK: - Initializers

    /// Create mode — the sheet opens with a blank event on the given date.
    init(selectedDate: Date) {
        self.existingEvent = nil
        _date = State(initialValue: selectedDate)
        _title = State(initialValue: "")
        _notes = State(initialValue: "")
        _tagTitle = State(initialValue: "")
        _tagColor = State(initialValue: Color(hex: "EBB533") ?? .yellow)
    }

    /// Edit mode — the sheet opens pre-filled with the existing event's data.
    init(event: EventEntity) {
        self.existingEvent = event
        _date = State(initialValue: event.date ?? Date())
        _title = State(initialValue: event.title ?? "")
        _notes = State(initialValue: event.notes ?? "")
        _tagTitle = State(initialValue: event.tagTitle ?? "")
        let hex = event.tagColorHex ?? "EBB533"
        _tagColor = State(initialValue: Color(hex: hex) ?? .yellow)
    }

    // MARK: - Body

    private var isEditing: Bool { existingEvent != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title", text: $title)
                    DatePicker("Date & Time", selection: $date)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(1...4)
                }

                Section("Tag (optional)") {
                    TextField("Tag title (e.g., Neurology)", text: $tagTitle)
                    ColorPicker("Tag color", selection: $tagColor, supportsOpacity: false)
                }

                // Delete option, only when editing
                if isEditing {
                    Section {
                        Button(role: .destructive) {
                            showDeleteConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash")
                                Text("Delete Event")
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Event" : "New Event")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { saveTapped() }
                        .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .confirmationDialog(
                "Delete this event?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let existing = existingEvent {
                        store.deleteEvent(existing)
                    }
                    dismiss()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This can't be undone.")
            }
        }
    }

    // MARK: - Save

    private func saveTapped() {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let finalTagTitle: String? = tagTitle.isEmpty ? nil : tagTitle
        let finalTagColor: String? = tagTitle.isEmpty ? nil : tagColor.hex6

        if let existing = existingEvent {
            // UPDATE — this is the path that used to be missing.
            store.updateEvent(
                existing,
                title: trimmed,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                tagTitle: finalTagTitle,
                tagColorHex: finalTagColor
            )
        } else {
            // CREATE
            store.addEvent(
                title: trimmed,
                date: date,
                notes: notes.isEmpty ? nil : notes,
                tagTitle: finalTagTitle,
                tagColorHex: finalTagColor
            )
        }
        dismiss()
    }
}
