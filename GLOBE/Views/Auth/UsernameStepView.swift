//======================================================================
// MARK: - UsernameStepView.swift  
// Purpose: Step 2 - Username input with uniqueness check
// Path: GLOBE/Views/Auth/UsernameStepView.swift
//======================================================================

import SwiftUI
import Supabase

struct UsernameStepView: View {
    @Binding var username: String
    let onNext: () -> Void

    @State private var isCheckingUsername = false
    @State private var usernameAvailable: Bool? = nil

    var body: some View {
        VStack(spacing: 0) {
            // Title
            VStack(spacing: 12) {
                Text("Pick a username")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .tracking(1)

                Text("This is your unique identifier.\nYou can change it later.")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(0.5)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 60)

            // Form
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 0) {
                        Text("@")
                            .font(.system(size: 17))
                            .foregroundColor(.white.opacity(0.5))
                            .padding(.leading, 16)

                        TextField("", text: $username, prompt: Text("Username").foregroundColor(.gray))
                            .font(.system(size: 17))
                            .foregroundColor(.white)
                            .textFieldStyle(PlainTextFieldStyle())
                            .padding(.leading, 4)
                            .padding(.trailing, 16)
                            .padding(.vertical, 16)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .textContentType(.username)
                            .onChange(of: username) { _, newValue in
                                let filtered = newValue.lowercased().filter { $0.isLetter || $0.isNumber || $0 == "_" }
                                if filtered != newValue {
                                    username = filtered
                                }
                                Task {
                                    await checkUsernameAvailability()
                                }
                            }

                        // Availability indicator
                        if isCheckingUsername {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                .scaleEffect(0.8)
                                .padding(.trailing, 16)
                        } else if let available = usernameAvailable, !username.isEmpty {
                            Image(systemName: available ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundColor(available ? .green : .red)
                                .padding(.trailing, 16)
                        }
                    }
                    .background(.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(usernameAvailable == false && !username.isEmpty ? Color.red.opacity(0.5) : .white.opacity(0.2), lineWidth: 1)
                    )

                    if usernameAvailable == false && !username.isEmpty {
                        Text("This username is already taken")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    } else if !username.isEmpty && username.count < 3 {
                        Text("Username must be at least 3 characters")
                            .font(.system(size: 12))
                            .foregroundColor(.orange.opacity(0.8))
                    }
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)

            // Next Button
            Button(action: onNext) {
                Text("Next")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(MinimalDesign.Colors.background)
                    .frame(maxWidth: .infinity)
                    .frame(height: 52)
                    .background(.white)
                    .cornerRadius(26)
            }
            .disabled(username.isEmpty || username.count < 3 || usernameAvailable != true)
            .opacity((username.isEmpty || username.count < 3 || usernameAvailable != true) ? 0.6 : 1.0)
            .padding(.horizontal, 32)
        }
    }

    private func checkUsernameAvailability() async {
        guard !username.isEmpty else {
            usernameAvailable = nil
            return
        }

        guard username.count >= 3 else {
            usernameAvailable = false
            return
        }

        isCheckingUsername = true
        defer { isCheckingUsername = false }

        do {
            let client = await SupabaseManager.shared.client
            let result = try await client
                .from("profiles")
                .select("username")
                .eq("username", value: username)
                .execute()

            let decoder = JSONDecoder()
            let profiles = try? decoder.decode([[String: String]].self, from: result.data)
            usernameAvailable = profiles?.isEmpty ?? true
        } catch {
            SecureLogger.shared.error("Failed to check username availability: \(error.localizedDescription)")
            usernameAvailable = nil
        }
    }
}
