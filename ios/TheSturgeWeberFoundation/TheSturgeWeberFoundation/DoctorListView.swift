//
//  DoctorListView.swift
//  TheSturgeWeberFoundation
//
//  Created by Anannya Reddy Gade on 10/11/25.
//

import SwiftUI

struct DoctorListView: View {
    @StateObject private var store = DoctorStore.shared

    @State private var search = ""
    @State private var showEditor = false
    @State private var editing: DoctorEntity? = nil

    var body: some View {
        ZStack {
            // Use simple background so it contrasts with Home/Calendar
            Color(.systemBackground).ignoresSafeArea()

            VStack(spacing: 10) {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                    TextField("Search by name, specialty, or phone…", text: $search)
                        .textInputAutocapitalization(.words)
                    if !search.isEmpty {
                        Button { search = "" } label: { Image(systemName: "xmark.circle.fill") }
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.gray.opacity(0.15), lineWidth: 1))
                .padding(.horizontal)

                if store.doctors.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "stethoscope")
                            .font(.system(size: 36))
                            .foregroundStyle(.secondary)
                        Text("No doctors yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Tap + to add your first provider.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 60)
                } else {
                    List {
                        ForEach(store.doctors) { doc in
                            Button {
                                editing = doc
                                showEditor = true
                            } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Circle()
                                        .fill(Color.swfPortWine.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                        .overlay(
                                            Image(systemName: "person.crop.circle")
                                                .font(.title2)
                                                .foregroundStyle(Color.swfPortWine)
                                        )

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(doc.name ?? "")
                                            .font(.headline)
                                        if let spec = doc.specialty, !spec.isEmpty {
                                            Text(spec).font(.subheadline).foregroundStyle(.secondary)
                                        }
                                        if let phone = doc.phone, !phone.isEmpty {
                                            Button {
                                                call(phone: phone)
                                            } label: {
                                                Label(phone, systemImage: "phone.fill")
                                                    .font(.caption)
                                            }
                                        }
                                        if let notes = doc.notes, !notes.isEmpty {
                                            Text(notes).font(.footnote).foregroundStyle(.secondary).lineLimit(2)
                                        }
                                    }
                                    Spacer(minLength: 0)
                                }
                                .contentShape(Rectangle())
                            }
                        }
                        .onDelete { idx in
                            for i in idx { store.delete(store.doctors[i]) }
                        }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle("Doctor Info")
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
                .accessibilityLabel("Add Doctor")
            }
        }
        .onChange(of: search) { _, _ in
            store.fetch(search: search)
        }
        .onAppear {
            store.fetch(search: search)
        }
        .sheet(isPresented: $showEditor) {
            DoctorEditorView(doctor: editing)
        }
    }

    private func call(phone: String) {
        let digits = phone.filter("0123456789+".contains)
        guard let url = URL(string: "tel://\(digits)"),
              UIApplication.shared.canOpenURL(url)
        else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack { DoctorListView() }
}
