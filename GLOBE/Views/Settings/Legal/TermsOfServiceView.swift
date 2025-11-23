//======================================================================
// MARK: - TermsOfServiceView.swift
// Purpose: Display terms of service for GLOBE app
// Path: GLOBE/Views/Settings/Legal/TermsOfServiceView.swift
//======================================================================
import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Terms of Service")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.text)
                    .padding(.bottom, 8)

                Text("Last Updated: November 24, 2025")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                    .padding(.bottom, 16)

                // Acceptance of Terms
                SectionView(
                    title: "1. Acceptance of Terms",
                    content: """
                    By accessing or using GLOBE, you agree to be bound by these Terms of Service and our Privacy Policy. If you do not agree to these terms, do not use the service.

                    These terms constitute a legally binding agreement between you and GLOBE. You must be at least 13 years old to use this service.
                    """
                )

                // Description of Service
                SectionView(
                    title: "2. Description of Service",
                    content: """
                    GLOBE is a location-based social networking platform that allows users to:

                    • Create posts tied to specific geographic locations
                    • View posts from other users on a map interface
                    • Interact with posts through likes and comments
                    • Follow other users and build social connections

                    Posts automatically expire after 24 hours. The service requires location permissions to function properly.
                    """
                )

                // User Accounts
                SectionView(
                    title: "3. User Accounts",
                    content: """
                    • You must provide accurate and complete information when creating an account
                    • You are responsible for maintaining the security of your account
                    • You are responsible for all activities that occur under your account
                    • You must immediately notify us of any unauthorized use
                    • You may not transfer your account to another person
                    • We reserve the right to suspend or terminate accounts that violate these terms
                    """
                )

                // User Conduct
                SectionView(
                    title: "4. User Conduct",
                    content: """
                    You agree NOT to:

                    • Post content that is illegal, harmful, threatening, abusive, harassing, defamatory, or otherwise objectionable
                    • Impersonate any person or entity
                    • Post content that infringes intellectual property rights
                    • Share personal information of others without consent
                    • Post spam or engage in manipulative behavior
                    • Use the service for commercial purposes without authorization
                    • Attempt to gain unauthorized access to the service or other users' accounts
                    • Post false or misleading location information
                    • Use automated systems (bots) without permission
                    • Engage in any activity that disrupts or interferes with the service
                    """
                )

                // Content Ownership and Rights
                SectionView(
                    title: "5. Content Ownership and Rights",
                    content: """
                    • You retain ownership of content you post
                    • By posting content, you grant GLOBE a worldwide, non-exclusive, royalty-free license to use, display, and distribute your content within the service
                    • You represent that you have the right to post the content and grant these licenses
                    • We reserve the right to remove content that violates these terms
                    • We are not responsible for user-generated content
                    """
                )

                // Location Services
                SectionView(
                    title: "6. Location Services",
                    content: """
                    • GLOBE requires access to your device's location services
                    • Location data is collected when you create posts
                    • Location data is displayed to other users as part of your posts
                    • You should not post from sensitive or private locations
                    • You are responsible for any consequences of sharing your location
                    • We are not liable for misuse of location data by other users
                    """
                )

                // Privacy and Data Protection
                SectionView(
                    title: "7. Privacy and Data Protection",
                    content: """
                    Your use of GLOBE is subject to our Privacy Policy, which is incorporated into these terms by reference. Please review our Privacy Policy to understand how we collect, use, and protect your information.
                    """
                )

                // Intellectual Property
                SectionView(
                    title: "8. Intellectual Property",
                    content: """
                    • GLOBE and its associated trademarks, logos, and service marks are owned by us
                    • The service's design, functionality, and content are protected by copyright and other intellectual property laws
                    • You may not copy, modify, distribute, or create derivative works without our permission
                    """
                )

                // Termination
                SectionView(
                    title: "9. Termination",
                    content: """
                    • You may terminate your account at any time through the app settings
                    • We may suspend or terminate your account for violations of these terms
                    • We may terminate or modify the service at any time without notice
                    • Upon termination, your right to use the service immediately ceases
                    • Certain provisions of these terms survive termination
                    """
                )

                // Disclaimers
                SectionView(
                    title: "10. Disclaimers",
                    content: """
                    THE SERVICE IS PROVIDED "AS IS" AND "AS AVAILABLE" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED.

                    WE DO NOT WARRANT THAT:
                    • The service will be uninterrupted or error-free
                    • Defects will be corrected
                    • The service is free of viruses or harmful components
                    • Results obtained from the service will be accurate or reliable
                    """
                )

                // Limitation of Liability
                SectionView(
                    title: "11. Limitation of Liability",
                    content: """
                    TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES, OR ANY LOSS OF PROFITS OR REVENUES.

                    Our total liability shall not exceed the amount you paid to use the service (currently $0).
                    """
                )

                // Indemnification
                SectionView(
                    title: "12. Indemnification",
                    content: """
                    You agree to indemnify and hold harmless GLOBE and its officers, directors, employees, and agents from any claims, damages, losses, liabilities, and expenses arising from:

                    • Your use of the service
                    • Your violation of these terms
                    • Your violation of any rights of another party
                    • Your content posted on the service
                    """
                )

                // Dispute Resolution
                SectionView(
                    title: "13. Dispute Resolution",
                    content: """
                    • These terms are governed by the laws of Japan
                    • Any disputes will be resolved in the courts of Tokyo, Japan
                    • You agree to first attempt to resolve disputes informally by contacting us
                    """
                )

                // Changes to Terms
                SectionView(
                    title: "14. Changes to Terms",
                    content: """
                    We reserve the right to modify these terms at any time. We will notify users of material changes through the app or via email. Continued use of the service after changes constitutes acceptance of the new terms.
                    """
                )

                // Contact Information
                SectionView(
                    title: "15. Contact Information",
                    content: """
                    If you have questions about these Terms of Service, please contact us:

                    Email: support@globe-app.com

                    We will respond to your inquiry within 30 days.
                    """
                )

                // Severability
                SectionView(
                    title: "16. Severability",
                    content: """
                    If any provision of these terms is found to be unenforceable, the remaining provisions will remain in full force and effect.
                    """
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Terms of Service")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        TermsOfServiceView()
    }
}
