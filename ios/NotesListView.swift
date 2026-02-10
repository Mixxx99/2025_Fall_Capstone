import SwiftUI

struct NotesListView: View {
    @StateObject private var store = NoteStore.shared

    @State private var search = ""
    @State private var typeFilter = "All"
    @State private var showEditor = false
    @State private var editing: NoteEntity? = nil

    private let types = ["All", "Medical", "Personal", "School", "Other"]

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 10) {
                // Search
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search notes…", text: $search)
                        .textInputAutocapitalization(.sentences)
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.15), lineWidth: 1))
                .padding(.horizontal)

                // Type chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(types, id: \.self) { t in
                            Button {
                                typeFilter = t
                                store.fetchNotes(search: search, type: typeFilter)
                            } label: {
                                Text(t)
                                    .font(.caption.bold())
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(t == typeFilter ? Color.swfPortWine.opacity(0.18) : Color.gray.opacity(0.12))
                                    .foregroundStyle(.primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // List
                List {
                    ForEach(store.notes) { note in
                        Button {
                            editing = note
                            showEditor = true
                        } label: {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 8) {
                                    Text(note.title ?? "")
                                        .font(.headline)

                                    // NEW: show custom tag chip if set
                                    if let tt = note.tagTitle,
                                       let hc = note.tagColorHex,
                                       let col = Color(hex: hc) {
                                        TagChip(title: tt, color: col)
                                    }

                                    Spacer()
                                    Text(note.updatedAt?.formatted(date: .abbreviated, time: .shortened) ?? "")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if let body = note.body, !body.isEmpty {
                                    Text(body).lineLimit(2).font(.subheadline).foregroundStyle(.secondary)
                                }

                                HStack(spacing: 8) {
                                    if let t = note.type, !t.isEmpty {
                                        Text(t)
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.swfPortWine.opacity(0.12))
                                            .clipShape(Capsule())
                                    }
                                    if let path = note.attachmentPath, !path.isEmpty {
                                        Label("Attachment", systemImage: "paperclip")
                                            .font(.caption2)
                                            .padding(.horizontal, 8)
                                            .padding(.vertical, 4)
                                            .background(Color.swfGoldenYellow.opacity(0.15))
                                            .clipShape(Capsule())
                                    }
                                }
                            }
                            .contentShape(Rectangle())
                        }
                    }
                    .onDelete { indexSet in
                        for idx in indexSet { store.delete(store.notes[idx]) }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("Notes")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    editing = nil
                    showEditor = true
                } label: { Image(systemName: "plus") }
                .foregroundStyle(.white)
                .accessibilityLabel("Add Note")
            }
        }
        .onChange(of: search) { _, _ in
            store.fetchNotes(search: search, type: typeFilter)
        }
        .onAppear {
            store.fetchNotes(search: search, type: typeFilter)
        }
        .sheet(isPresented: $showEditor) {
            NoteEditorView(note: editing)
        }
    }
}

#Preview {
    NavigationStack { NotesListView() }
}
