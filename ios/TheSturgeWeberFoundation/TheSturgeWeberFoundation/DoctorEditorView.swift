//
//  DoctorEditorView.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import SwiftUI

struct DoctorEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var store = DoctorStore.shared

    let doctor: DoctorEntity?  // nil = create, non-nil = edit

    @State private var name: String = ""
    @State private var specialty: String = ""
    @State private var phone: String = ""
    @State private var notes: String = ""

    init(doctor: DoctorEntity?) {
        self.doctor = doctor
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Name *") {
                    TextField("Dr. Jane Doe", text: $name)
                        .textInputAutocapitalization(.words)
                }
                Section("Specialty") {
                    TextField("Neurologist", text: $specialty)
                        .textInputAutocapitalization(.words)
                }
                Section("Phone") {
                    TextField("(555) 123-4567", text: $phone)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                }
                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 140)
                }
            }
            .navigationTitle(doctor == nil ? "New Doctor" : "Edit Doctor")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        if let d = doctor {
                            store.update(d,
                                         name: trimmed,
                                         specialty: specialty.isEmpty ? nil : specialty,
                                         phone: phone.isEmpty ? nil : phone,
                                         notes: notes.isEmpty ? nil : notes)
                        } else {
                            store.add(name: trimmed,
                                      specialty: specialty.isEmpty ? nil : specialty,
                                      phone: phone.isEmpty ? nil : phone,
                                      notes: notes.isEmpty ? nil : notes)
                        }
                        dismiss()
                    }
                }
            }
            .onAppear {
                if let d = doctor {
                    name = d.name ?? ""
                    specialty = d.specialty ?? ""
                    phone = d.phone ?? ""
                    notes = d.notes ?? ""
                } else {
                    name = ""; specialty = ""; phone = ""; notes = ""
                }
            }
        }
    }
}

#Preview {
    DoctorEditorView(doctor: nil)
}
