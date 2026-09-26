import SwiftUI
import PhotosUI

/// User Profile page - view/edit name, photo, settings, change passcode, logout
struct UserProfileView: View {
    @StateObject private var profile = UserProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var editingName = false
    @State private var editingEmail = false
    @State private var draftName = ""
    @State private var draftEmail = ""
    @State private var showPhotoPicker = false
    @State private var selectedPhotoItem: PhotosPickerItem?
    @State private var showChangePasscode = false
    @State private var showDeleteAlert = false
    @State private var showLogoutAlert = false

    var body: some View {
        ZStack {
            Color(.systemGroupedBackground).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    profileHeader
                    infoSection
                    settingsSection
                    accountSection
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("My Profile")
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarBackground(Color.swfGreen, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showChangePasscode) {
            ChangePasscodeView()
        }
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Log Out", role: .destructive) {
                profile.logout()
            }
        } message: {
            Text("Are you sure you want to log out?")
        }
        .alert("Delete Account", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                profile.deleteAccount()
            }
        } message: {
            Text("This will permanently delete your account and all local data. This cannot be undone.")
        }
    }

    // MARK: - Profile Header (Photo + Name)

    private var profileHeader: some View {
        VStack(spacing: 12) {
            // Profile Photo
            ZStack(alignment: .bottomTrailing) {
                if let image = profile.profileImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 100, height: 100)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(Color.swfGoldenYellow, lineWidth: 3))
                } else {
                    Circle()
                        .fill(Color.swfGreen.opacity(0.2))
                        .frame(width: 100, height: 100)
                        .overlay(
                            Text(initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundStyle(Color.swfGreen)
                        )
                        .overlay(Circle().stroke(Color.swfGoldenYellow, lineWidth: 3))
                }

                PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
                    Circle()
                        .fill(Color.swfPortWine)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera.fill")
                                .font(.caption)
                                .foregroundStyle(.white)
                        )
                }
            }
            .onChange(of: selectedPhotoItem) { _, newValue in
                loadPhoto(from: newValue)
            }

            // Name
            Text(profile.userName.isEmpty ? "Warrior" : profile.userName)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            if !profile.userEmail.isEmpty {
                Text(profile.userEmail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 6, y: 2)
        )
        .padding(.top, 8)
    }

    // MARK: - Info Section

    private var infoSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Personal Information")

            VStack(spacing: 0) {
                // Name
                editableRow(
                    icon: "person.fill",
                    label: "Name",
                    value: profile.userName.isEmpty ? "Tap to set" : profile.userName,
                    isEditing: $editingName,
                    draft: $draftName
                ) {
                    profile.userName = draftName
                    editingName = false
                }
                .onAppear { draftName = profile.userName }

                Divider().padding(.leading, 52)

                // Email
                editableRow(
                    icon: "envelope.fill",
                    label: "Email",
                    value: profile.userEmail.isEmpty ? "Tap to set" : profile.userEmail,
                    isEditing: $editingEmail,
                    draft: $draftEmail
                ) {
                    profile.userEmail = draftEmail
                    editingEmail = false
                }
                .onAppear { draftEmail = profile.userEmail }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            )
        }
    }

    // MARK: - Settings Section

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Preferences")

            VStack(spacing: 0) {
                // Notifications toggle
                HStack(spacing: 12) {
                    Image(systemName: "bell.fill")
                        .font(.body)
                        .foregroundStyle(Color.swfPortWine)
                        .frame(width: 28)

                    Text("Medication Reminders")
                        .font(.body)

                    Spacer()

                    Toggle("", isOn: $profile.notificationsEnabled)
                        .tint(Color.swfGreen)
                        .labelsHidden()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .onChange(of: profile.notificationsEnabled) { _, enabled in
                    if enabled {
                        NotificationManager.shared.requestPermission()
                    }
                }

                if profile.notificationsEnabled {
                    Divider().padding(.leading, 52)

                    // Reminder time
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
                            .font(.body)
                            .foregroundStyle(Color.swfGoldenYellow)
                            .frame(width: 28)

                        Text("Remind me")
                            .font(.body)

                        Spacer()

                        Picker("", selection: $profile.reminderHoursBefore) {
                            Text("1 hour before").tag(1)
                            Text("2 hours before").tag(2)
                            Text("6 hours before").tag(6)
                            Text("12 hours before").tag(12)
                            Text("1 day before").tag(24)
                            Text("2 days before").tag(48)
                        }
                        .tint(Color.swfGreen)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            )
        }
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            sectionHeader("Account")

            VStack(spacing: 0) {
                // Change Passcode
                Button {
                    showChangePasscode = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "lock.fill")
                            .font(.body)
                            .foregroundStyle(Color.swfGreen)
                            .frame(width: 28)
                        Text("Change Passcode")
                            .font(.body)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                Divider().padding(.leading, 52)

                // Log Out
                Button {
                    showLogoutAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.body)
                            .foregroundStyle(.orange)
                            .frame(width: 28)
                        Text("Log Out")
                            .font(.body)
                            .foregroundStyle(.orange)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }

                Divider().padding(.leading, 52)

                // Delete Account
                Button {
                    showDeleteAlert = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "trash.fill")
                            .font(.body)
                            .foregroundStyle(.red)
                            .frame(width: 28)
                        Text("Delete Account")
                            .font(.body)
                            .foregroundStyle(.red)
                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
            )

            // App version
            Text("Warrior University v1.0 • Build 2026.03")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .frame(maxWidth: .infinity)
                .padding(.top, 12)
        }
    }

    // MARK: - Helpers

    private var initials: String {
        let parts = profile.userName.split(separator: " ")
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "WU"
    }

    private func sectionHeader(_ title: String) -> some View {
        Text(title.uppercased())
            .font(.caption.bold())
            .foregroundStyle(.secondary)
            .padding(.leading, 4)
            .padding(.bottom, 2)
    }

    @ViewBuilder
    private func editableRow(
        icon: String,
        label: String,
        value: String,
        isEditing: Binding<Bool>,
        draft: Binding<String>,
        onSave: @escaping () -> Void
    ) -> some View {
        if isEditing.wrappedValue {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundStyle(Color.swfGreen)
                    .frame(width: 28)
                TextField(label, text: draft)
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .onSubmit(onSave)
                Button("Save") { onSave() }
                    .font(.subheadline.bold())
                    .foregroundStyle(Color.swfPortWine)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        } else {
            Button {
                isEditing.wrappedValue = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: icon)
                        .font(.body)
                        .foregroundStyle(Color.swfGreen)
                        .frame(width: 28)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(label)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(value)
                            .font(.body)
                            .foregroundStyle(value == "Tap to set" ? .tertiary : .primary)
                    }
                    Spacer()
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
    }

    private func loadPhoto(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let img = UIImage(data: data) {
                    profile.setProfileImage(img)
                }
            }
        }
    }
}

// MARK: - Change Passcode View

struct ChangePasscodeView: View {
    @StateObject private var profile = UserProfileStore.shared
    @Environment(\.dismiss) private var dismiss

    @State private var currentPasscode = ""
    @State private var newPasscode = ""
    @State private var confirmPasscode = ""
    @State private var errorMessage = ""
    @State private var showSuccess = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground).ignoresSafeArea()

                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 16) {
                        passcodeField(label: "Current Passcode", text: $currentPasscode)
                        passcodeField(label: "New Passcode", text: $newPasscode)
                        passcodeField(label: "Confirm New Passcode", text: $confirmPasscode)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(.white)
                            .shadow(color: .black.opacity(0.04), radius: 4, y: 1)
                    )
                    .padding(.horizontal)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.subheadline)
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }

                    if showSuccess {
                        Label("Passcode changed successfully!", systemImage: "checkmark.circle.fill")
                            .font(.subheadline)
                            .foregroundStyle(.green)
                            .padding(.horizontal)
                    }

                    Button {
                        changePasscode()
                    } label: {
                        Text("Change Passcode")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(canSubmit ? Color.swfPortWine : Color.gray.opacity(0.3))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                    }
                    .disabled(!canSubmit)
                    .padding(.horizontal, 32)

                    Spacer()
                }
                .padding(.top, 20)
            }
            .navigationTitle("Change Passcode")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private var canSubmit: Bool {
        currentPasscode.count == 4 && newPasscode.count == 4 && confirmPasscode.count == 4
    }

    private func passcodeField(label: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            SecureField("4-digit passcode", text: text)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .onChange(of: text.wrappedValue) { _, newVal in
                    // Limit to 4 digits
                    if newVal.count > 4 {
                        text.wrappedValue = String(newVal.prefix(4))
                    }
                    // Only allow digits
                    text.wrappedValue = text.wrappedValue.filter { $0.isNumber }
                }
        }
    }

    private func changePasscode() {
        errorMessage = ""
        showSuccess = false

        guard newPasscode == confirmPasscode else {
            errorMessage = "New passcodes don't match."
            return
        }
        guard newPasscode != currentPasscode else {
            errorMessage = "New passcode must be different."
            return
        }

        if profile.changePasscode(oldPasscode: currentPasscode, newPasscode: newPasscode) {
            showSuccess = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { dismiss() }
        } else {
            errorMessage = "Current passcode is incorrect."
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        UserProfileView()
    }
}
