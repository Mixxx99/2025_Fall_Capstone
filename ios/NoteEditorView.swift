import SwiftUI

struct NoteEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = NoteStore.shared

    let note: NoteEntity?

    @State private var title: String = ""
    @State private var bodyText: String = ""
    @State private var type: String = "Other"
    @State private var attachmentPath: String = ""
    @State private var userId: String = ""   // optional

    // NEW: custom tag
    @State private var tagTitle: String = ""
    @State private var tagColor: Color = .swfPortWine

    private let types = ["Medical", "Personal", "School", "Other"]

    init(note: NoteEntity?) { self.note = note }

    var body: some View {
        NavigationStack {
            Form {
                Section("Title") {
                    TextField("Enter title", text: $title)
                        .textInputAutocapitalization(.sentences)
                }
                Section("Type") {
                    Picker("Type", selection: $type) {
                        ForEach(types, id: \.self) { Text($0).tag($0) }
                    }
                }

                // NEW: Tag section
                Section("Tag (optional)") {
                    TextField("Tag title (e.g., Seizure Log)", text: $tagTitle)
                    ColorPicker("Tag color", selection: $tagColor, supportsOpacity: false)
                }

                Section("Body") {
                    TextEditor(text: $bodyText).frame(minHeight: 180)
                }
                Section("Attachment (path/URL)") {
                    TextField("e.g. file:///… or https://…", text: $attachmentPath)
                        .textInputAutocapitalization(.never)
                        .textContentType(.URL)
                        .keyboardType(.URL)
                }
            }
            .navigationTitle(note == nil ? "New Note" : "Edit Note")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !t.isEmpty else { return }
                        if let n = note {
                            store.update(n,
                                         title: t,
                                         body: bodyText.isEmpty ? nil : bodyText,
                                         userId: userId.isEmpty ? nil : userId,
                                         attachmentPath: attachmentPath.isEmpty ? nil : attachmentPath,
                                         type: type,
                                         tagTitle: tagTitle.isEmpty ? nil : tagTitle,
                                         tagColorHex: tagTitle.isEmpty ? nil : tagColor.hex6)
                        } else {
                            store.add(title: t,
                                      body: bodyText.isEmpty ? nil : bodyText,
                                      userId: userId.isEmpty ? nil : userId,
                                      attachmentPath: attachmentPath.isEmpty ? nil : attachmentPath,
                                      type: type,
                                      tagTitle: tagTitle.isEmpty ? nil : tagTitle,
                                      tagColorHex: tagTitle.isEmpty ? nil : tagColor.hex6)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let n = note {
                    title = n.title ?? ""
                    bodyText = n.body ?? ""
                    type = n.type ?? "Other"
                    attachmentPath = n.attachmentPath ?? ""
                    userId = n.userId ?? ""

                    // NEW: populate tag
                    tagTitle = n.tagTitle ?? ""
                    if let hx = n.tagColorHex, let c = Color(hex: hx) { tagColor = c }
                } else {
                    title = ""; bodyText = ""; type = "Other"; attachmentPath = ""; userId = ""
                    tagTitle = ""; tagColor = .swfPortWine
                }
            }
        }
    }
}

#Preview { NoteEditorView(note: nil) }
