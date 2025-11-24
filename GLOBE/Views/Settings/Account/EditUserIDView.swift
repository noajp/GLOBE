//======================================================================
// MARK: - EditUserIDView.swift
// Purpose: Edit user ID with validation
// Path: GLOBE/Views/Settings/Account/EditUserIDView.swift
//======================================================================
import SwiftUI
import Supabase

struct EditUserIDView: View {
    let currentUserID: String
    let onSave: (String) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var editedUserID: String = ""
    @State private var isValid = false
    @State private var isChecking = false
    @State private var validationMessage = ""
    @State private var isSaving = false

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            VStack(alignment: .leading, spacing: 24) {
                // Input field
                VStack(alignment: .leading, spacing: 8) {
                    Text("User ID")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)

                    HStack(spacing: 0) {
                        Text("@")
                            .font(.system(size: 17))
                            .foregroundColor(MinimalDesign.Colors.text)

                        TextField("", text: $editedUserID)
                            .font(.system(size: 17))
                            .foregroundColor(MinimalDesign.Colors.text)
                            .autocapitalization(.none)
                            .disableAutocorrection(true)
                            .onChange(of: editedUserID) { newValue in
                                Task {
                                    await checkUserIDAvailability(newValue)
                                }
                            }
                    }
                    .padding(12)
                    .background(MinimalDesign.Colors.secondaryBackground)
                    .cornerRadius(8)
                }

                // Validation status
                if isChecking {
                    HStack(spacing: 8) {
                        ProgressView()
                        Text("Checking availability...")
                            .font(.system(size: 14))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                    }
                } else if !validationMessage.isEmpty {
                    HStack(spacing: 8) {
                        Image(systemName: isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(isValid ? .green : .red)
                        Text(validationMessage)
                            .font(.system(size: 14))
                            .foregroundColor(isValid ? .green : .red)
                    }
                }

                // Info text
                Text("User ID must be 3-30 characters and can only contain lowercase letters, numbers, and underscores. This will be your unique identifier across the app.")
                    .font(.system(size: 13))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                    .lineSpacing(4)

                Spacer()

                // Save button
                Button(action: {
                    Task {
                        await saveUserID()
                    }
                }) {
                    if isSaving {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    } else {
                        Text("Save")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
                .background(isValid && !isSaving ? Color.blue : Color.gray)
                .cornerRadius(8)
                .disabled(!isValid || isSaving)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .navigationTitle("Edit User ID")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            editedUserID = currentUserID.replacingOccurrences(of: "@", with: "")
        }
    }

    private func checkUserIDAvailability(_ userid: String) async {
        isChecking = true
        isValid = false
        validationMessage = ""

        let cleanedUserID = userid.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "@", with: "")

        // Basic validation
        guard !cleanedUserID.isEmpty else {
            isChecking = false
            validationMessage = "User ID cannot be empty"
            return
        }

        guard cleanedUserID.count >= 3 && cleanedUserID.count <= 30 else {
            isChecking = false
            validationMessage = "User ID must be 3-30 characters"
            return
        }

        guard cleanedUserID.allSatisfy({ $0.isLetter || $0.isNumber || $0 == "_" }) else {
            isChecking = false
            validationMessage = "Only lowercase letters, numbers, and underscores allowed"
            return
        }

        // Check if same as current
        if cleanedUserID == currentUserID.replacingOccurrences(of: "@", with: "") {
            isChecking = false
            isValid = true
            validationMessage = "This is your current User ID"
            return
        }

        // Check database for duplicates
        do {
            let response = try await supabase
                .from("profiles")
                .select("id")
                .eq("userid", value: cleanedUserID)
                .execute()

            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([UserProfile].self, from: response.data)

            if profiles?.isEmpty ?? true {
                isValid = true
                validationMessage = "✓ This User ID is available"
            } else {
                isValid = false
                validationMessage = "This User ID is already taken"
            }
        } catch {
            validationMessage = "Error checking User ID"
        }

        isChecking = false
    }

    private func saveUserID() async {
        isSaving = true

        let cleanedUserID = editedUserID.trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "@", with: "")

        onSave(cleanedUserID)

        isSaving = false
        dismiss()
    }
}

#Preview {
    NavigationStack {
        EditUserIDView(currentUserID: "johndoe", onSave: { _ in })
    }
}
