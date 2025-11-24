//======================================================================
// MARK: - CommunityGuidelinesView.swift
// Purpose: Display community guidelines for GLOBE app
// Path: GLOBE/Views/Settings/Legal/CommunityGuidelinesView.swift
//======================================================================
import SwiftUI

struct CommunityGuidelinesView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Community Guidelines")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(MinimalDesign.Colors.text)
                    .padding(.bottom, 8)

                Text("Last Updated: November 24, 2025")
                    .font(.system(size: 14))
                    .foregroundColor(MinimalDesign.Colors.textSecondary)
                    .padding(.bottom, 16)

                // Introduction
                SectionView(
                    title: "Welcome to GLOBE",
                    content: """
                    GLOBE is a community for sharing moments and discoveries tied to real-world locations. These guidelines help ensure our community remains safe, respectful, and enjoyable for everyone.

                    By using GLOBE, you agree to follow these community guidelines. Violations may result in content removal, account suspension, or permanent ban.
                    """
                )

                // Be Respectful
                SectionView(
                    title: "1. Be Respectful",
                    content: """
                    • Treat others with kindness and respect
                    • Respect different opinions, backgrounds, and cultures
                    • Disagree respectfully without personal attacks
                    • Consider how your posts might affect others
                    • Remember that real people are behind every account
                    """
                )

                // Safety First
                SectionView(
                    title: "2. Safety First",
                    content: """
                    • Do not post content that threatens or endangers others
                    • Do not share posts that could lead to physical harm
                    • Be cautious about sharing your exact location
                    • Do not post from private residences or sensitive locations
                    • Report dangerous or threatening content immediately
                    • Do not coordinate or promote illegal activities
                    """
                )

                // Prohibited Content
                SectionView(
                    title: "3. Prohibited Content",
                    content: """
                    DO NOT post content that contains:

                    • Violence or graphic content
                    • Hate speech or discrimination based on race, ethnicity, religion, gender, sexual orientation, disability, or other protected characteristics
                    • Harassment, bullying, or threats
                    • Sexual content or nudity
                    • Self-harm or suicide-related content
                    • Illegal activities or dangerous challenges
                    • Misinformation that could cause harm
                    • Spam or misleading content
                    • Copyright or trademark infringement
                    """
                )

                // Privacy and Personal Information
                SectionView(
                    title: "4. Privacy and Personal Information",
                    content: """
                    • Do not share other people's personal information (doxxing)
                    • Do not post photos of others without their consent
                    • Be mindful of what location information you share
                    • Do not use GLOBE to stalk or track others
                    • Respect others' privacy settings and boundaries
                    """
                )

                // Authentic Behavior
                SectionView(
                    title: "5. Authentic Behavior",
                    content: """
                    • Be yourself and represent yourself honestly
                    • Do not impersonate others or create fake accounts
                    • Do not mislead others about your identity or location
                    • Do not manipulate the system with fake engagement
                    • Multiple accounts should not be used to evade restrictions
                    """
                )

                // Location Guidelines
                SectionView(
                    title: "6. Location Guidelines",
                    content: """
                    • Post accurate location information
                    • Do not post false or misleading locations
                    • Be respectful when posting at historical or memorial sites
                    • Do not post from restricted or prohibited areas
                    • Consider the privacy of locations you post from
                    • Do not use location features to harass or track others
                    """
                )

                // Intellectual Property
                SectionView(
                    title: "7. Intellectual Property",
                    content: """
                    • Only post content you have the right to share
                    • Give credit to creators when sharing others' work
                    • Do not post copyrighted material without permission
                    • Respect trademarks and brand identities
                    • Do not use GLOBE for commercial purposes without authorization
                    """
                )

                // Spam and Manipulation
                SectionView(
                    title: "8. Spam and Manipulation",
                    content: """
                    • Do not post repetitive or unsolicited content
                    • Do not artificially inflate engagement metrics
                    • Do not use bots or automated systems
                    • Do not mislead users to gain followers or engagement
                    • Do not coordinate inauthentic behavior
                    """
                )

                // Platform Integrity
                SectionView(
                    title: "9. Platform Integrity",
                    content: """
                    • Do not attempt to hack or exploit the service
                    • Do not interfere with other users' experience
                    • Do not circumvent security measures
                    • Report bugs and vulnerabilities responsibly
                    • Do not scrape or collect data without permission
                    """
                )

                // Age Requirements
                SectionView(
                    title: "10. Age Requirements",
                    content: """
                    • You must be at least 13 years old to use GLOBE
                    • Do not lie about your age
                    • Parents and guardians should supervise minors' use
                    • We reserve the right to verify age and remove underage accounts
                    """
                )

                // Reporting Violations
                SectionView(
                    title: "11. Reporting Violations",
                    content: """
                    If you see content or behavior that violates these guidelines:

                    • Use the in-app reporting feature
                    • Provide detailed information about the violation
                    • Do not engage with or amplify harmful content
                    • Contact support@globe-app.com for serious concerns

                    We review all reports and take appropriate action. False reports may result in consequences for the reporter.
                    """
                )

                // Enforcement
                SectionView(
                    title: "12. Enforcement",
                    content: """
                    Violations may result in:

                    • Warning or educational notice
                    • Content removal
                    • Temporary account restriction
                    • Temporary account suspension
                    • Permanent account ban
                    • Reporting to law enforcement (for illegal activities)

                    The severity of the consequence depends on the violation type, frequency, and context. We reserve the right to take action without warning for serious violations.
                    """
                )

                // Appeals
                SectionView(
                    title: "13. Appeals",
                    content: """
                    If you believe we made a mistake:

                    • You can appeal enforcement actions
                    • Contact support@globe-app.com with your appeal
                    • Include your account information and explanation
                    • We will review and respond within 30 days

                    Appeals are not guaranteed to result in a reversal of action.
                    """
                )

                // Updates
                SectionView(
                    title: "14. Updates to Guidelines",
                    content: """
                    We may update these guidelines as our community grows and evolves. We will notify users of significant changes. Continued use of GLOBE after changes constitutes acceptance of the updated guidelines.
                    """
                )

                // Contact Us
                SectionView(
                    title: "15. Questions?",
                    content: """
                    If you have questions about these Community Guidelines:

                    Email: support@globe-app.com

                    Thank you for helping make GLOBE a safe and welcoming community!
                    """
                )
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
        }
        .background(MinimalDesign.Colors.background)
        .navigationTitle("Community Guidelines")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        CommunityGuidelinesView()
    }
}
