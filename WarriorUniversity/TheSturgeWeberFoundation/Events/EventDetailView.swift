import SwiftUI

/// Read-only detail view for an event, with toolbar actions to edit or
/// delete. Tapping Edit brings up the same EditEventView used for
/// creation, pre-filled with the event's current values.
struct EventDetailView: View {
    @EnvironmentObject var store: EventStore
    @Environment(\.dismiss) private var dismiss
    let event: EventEntity

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(event.title ?? "")
                    .font(.largeTitle).bold()

                Text(event.date?.formatted(date: .abbreviated, time: .shortened) ?? "")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                // Tag chip (if any)
                if let tagTitle = event.tagTitle,
                   !tagTitle.isEmpty {
                    let hex = event.tagColorHex ?? "EBB533"
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color(hex: hex) ?? .yellow)
                            .frame(width: 10, height: 10)
                        Text(tagTitle)
                            .font(.subheadline.weight(.medium))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule().fill(Color.secondary.opacity(0.12))
                    )
                }

                if let notes = event.notes, !notes.isEmpty {
                    Text(notes)
                        .padding(.top, 4)
                }

                Spacer(minLength: 0)
            }
            .padding()
        }
        .navigationTitle("Event Details")
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    showEdit = true
                } label: {
                    Image(systemName: "pencil")
                }
                .accessibilityLabel("Edit Event")

                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Image(systemName: "trash")
                }
                .accessibilityLabel("Delete Event")
            }
        }
        .sheet(isPresented: $showEdit) {
            EditEventView(event: event)
                .environmentObject(store)
        }
        .confirmationDialog(
            "Delete this event?",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("Delete", role: .destructive) {
                store.deleteEvent(event)
                dismiss()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("This can't be undone.")
        }
    }
}
