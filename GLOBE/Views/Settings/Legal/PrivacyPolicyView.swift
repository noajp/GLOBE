//======================================================================
// MARK: - PrivacyPolicyView.swift
// Purpose: Display privacy policy for GLOBE app
// Path: GLOBE/Views/Settings/Legal/PrivacyPolicyView.swift
//======================================================================
import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Privacy Policy")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.text)
                    .padding(.bottom, 8)

                Text("Last Updated: November 24, 2025")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                    .padding(.bottom, 16)

                // Introduction
                SectionView(
                    title: "1. Introduction",
                    content: """
                    Welcome to GLOBE. We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and protect your information when you use our location-based social networking service.

                    GLOBE is a location-based social media platform that allows users to share posts tied to geographic locations. By using GLOBE, you agree to the collection and use of information in accordance with this policy.
                    """
                )

                // Information We Collect
                SectionView(
                    title: "2. Information We Collect",
                    content: """
                    We collect the following types of information:

                    • Account Information: Email address, username, display name, profile photo, and bio

                    • Location Information: Precise geographic location data when you create posts or use location features. You can control location permissions in your device settings.

                    • Content: Posts, photos, comments, and likes you create or interact with

                    • Usage Data: How you interact with the app, including posts viewed, searches performed, and features used

                    • Device Information: Device type, operating system, unique device identifiers, and mobile network information
                    """
                )

                // How We Use Your Information
                SectionView(
                    title: "3. How We Use Your Information",
                    content: """
                    We use your information to:

                    • Provide and improve our services
                    • Display your posts on the map at specified locations
                    • Enable social features (following, liking, commenting)
                    • Ensure safety and security of the platform
                    • Prevent fraud and abuse
                    • Comply with legal obligations
                    • Communicate with you about service updates
                    """
                )

                // Location Data
                SectionView(
                    title: "4. Location Data",
                    content: """
                    Location data is central to GLOBE's functionality:

                    • We collect precise location data when you create posts
                    • Location data is stored with your posts and displayed to other users
                    • You can control location permissions in your device settings
                    • Denying location access will limit your ability to create posts
                    • We do not track your location when the app is not in use
                    • Location history is not stored beyond the posts you create
                    """
                )

                // Data Sharing
                SectionView(
                    title: "5. Data Sharing",
                    content: """
                    We do not sell your personal information. We may share your data:

                    • With other users: Your posts, profile information, and location data (as part of posts) are visible to other GLOBE users

                    • Service providers: We use third-party services (Supabase) to host and store data

                    • Legal requirements: When required by law or to protect rights and safety

                    • Business transfers: In the event of a merger, acquisition, or sale of assets
                    """
                )

                // Data Retention
                SectionView(
                    title: "6. Data Retention",
                    content: """
                    • Posts expire and are automatically deleted after 24 hours
                    • Profile data is retained while your account is active
                    • You can delete your account at any time in Settings
                    • Upon account deletion, your data will be removed within 30 days
                    • Some data may be retained for legal or security purposes
                    """
                )

                // Your Rights
                SectionView(
                    title: "7. Your Rights",
                    content: """
                    You have the right to:

                    • Access your personal data
                    • Correct inaccurate data
                    • Delete your account and data
                    • Export your data
                    • Object to certain data processing
                    • Withdraw consent at any time

                    To exercise these rights, contact us at support@globe-app.com
                    """
                )

                // Children's Privacy
                SectionView(
                    title: "8. Children's Privacy",
                    content: """
                    GLOBE is not intended for users under 13 years of age. We do not knowingly collect personal information from children under 13. If you believe we have collected information from a child under 13, please contact us immediately.
                    """
                )

                // Security
                SectionView(
                    title: "9. Security",
                    content: """
                    We implement appropriate technical and organizational measures to protect your data:

                    • Data encryption in transit and at rest
                    • Secure authentication mechanisms
                    • Regular security audits
                    • Input validation and sanitization
                    • Rate limiting and abuse prevention

                    However, no method of transmission over the internet is 100% secure. We cannot guarantee absolute security.
                    """
                )

                // International Data Transfers
                SectionView(
                    title: "10. International Data Transfers",
                    content: """
                    Your data may be transferred to and processed in countries other than your country of residence. We ensure appropriate safeguards are in place to protect your data in accordance with this privacy policy.
                    """
                )

                // Changes to This Policy
                SectionView(
                    title: "11. Changes to This Policy",
                    content: """
                    We may update this privacy policy from time to time. We will notify you of any changes by posting the new policy on this page and updating the "Last Updated" date. You are advised to review this policy periodically for any changes.
                    """
                )

                // Contact Us
                SectionView(
                    title: "12. Contact Us",
                    content: """
                    If you have any questions about this Privacy Policy, please contact us:

                    Email: support@globe-app.com

                    We will respond to your inquiry within 30 days.
                    """
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Privacy Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Section View Component
struct SectionView: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.text)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(MinimalDesign.Colors.textSecondary)
                .lineSpacing(4)
        }
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
