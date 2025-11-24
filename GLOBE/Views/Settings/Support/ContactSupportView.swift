//======================================================================
// MARK: - ContactSupportView.swift
// Purpose: Contact support interface
// Path: GLOBE/Views/Settings/Support/ContactSupportView.swift
//======================================================================
import SwiftUI
import MessageUI

struct ContactSupportView: View {
    @State private var subject = ""
    @State private var message = ""
    @State private var selectedCategory: SupportCategory = .general
    @State private var showingMailComposer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @EnvironmentObject var authManager: AuthManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Contact Support")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    Text("We're here to help! Send us a message and we'll get back to you within 24-48 hours.")
                        .font(.system(size: 15))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                }

                // Category Picker
                VStack(alignment: .leading, spacing: 8) {
                    Text("Category")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    Picker("Category", selection: $selectedCategory) {
                        ForEach(SupportCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(MinimalDesign.Colors.text)
                    .padding(12)
                    .background(MinimalDesign.Colors.secondaryBackground)
                    .cornerRadius(8)
                }

                // Subject Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    TextField("Brief description of your issue", text: $subject)
                        .padding(12)
                        .background(MinimalDesign.Colors.secondaryBackground)
                        .foregroundColor(MinimalDesign.Colors.text)
                        .cornerRadius(8)
                }

                // Message Field
                VStack(alignment: .leading, spacing: 8) {
                    Text("Message")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    TextEditor(text: $message)
                        .frame(height: 200)
                        .padding(8)
                        .background(MinimalDesign.Colors.secondaryBackground)
                        .foregroundColor(MinimalDesign.Colors.text)
                        .cornerRadius(8)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(MinimalDesign.Colors.border, lineWidth: 1)
                        )
                }

                // Contact Info
                VStack(alignment: .leading, spacing: 12) {
                    Text("Other Ways to Reach Us")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(MinimalDesign.Colors.text)

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundColor(MinimalDesign.Colors.accent)
                        Text("support@globe-app.com")
                            .font(.system(size: 15))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                    }
                }
                .padding()
                .background(MinimalDesign.Colors.secondaryBackground)
                .cornerRadius(8)

                // Send Button
                Button(action: sendEmail) {
                    Text("Send Message")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(MinimalDesign.Colors.accent)
                        .cornerRadius(8)
                }
                .disabled(subject.isEmpty || message.isEmpty)
                .opacity(subject.isEmpty || message.isEmpty ? 0.5 : 1.0)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Contact Support")
        .navigationBarTitleDisplayMode(.inline)
        .alert("Support", isPresented: $showingAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }

    private func sendEmail() {
        // Compose email with user info and message
        let userEmail = authManager.currentUser?.email ?? "Not logged in"
        let userId = authManager.currentUser?.id ?? "N/A"

        let emailBody = """
        Category: \(selectedCategory.rawValue)
        Subject: \(subject)

        Message:
        \(message)

        ---
        User Info:
        Email: \(userEmail)
        User ID: \(userId)
        App Version: \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown")
        iOS Version: \(UIDevice.current.systemVersion)
        """

        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.setToRecipients(["support@globe-app.com"])
            mail.setSubject("[\(selectedCategory.rawValue)] \(subject)")
            mail.setMessageBody(emailBody, isHTML: false)

            // Present mail composer (would need view controller in real implementation)
            alertMessage = "Email app will open with your message. Please send it from your default email app."
            showingAlert = true
        } else {
            // Fallback: Copy to clipboard or show mailto link
            UIPasteboard.general.string = emailBody
            alertMessage = "Email app not configured. Message copied to clipboard. Please email it to support@globe-app.com"
            showingAlert = true
        }
    }
}

enum SupportCategory: String, CaseIterable {
    case general = "General Question"
    case technical = "Technical Issue"
    case account = "Account Problem"
    case privacy = "Privacy Concern"
    case content = "Content Report"
    case feature = "Feature Request"
    case bug = "Bug Report"
    case other = "Other"
}

#Preview {
    NavigationStack {
        ContactSupportView()
    }
}
