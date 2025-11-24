//======================================================================
// MARK: - CommercialTransactionsView.swift
// Purpose: Display commercial transactions act compliance information
// Path: GLOBE/Views/Settings/Legal/CommercialTransactionsView.swift
//======================================================================
import SwiftUI

struct CommercialTransactionsView: View {
    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Commercial Transactions Act")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.text)
                        .padding(.bottom, 8)

                    Text("Last Updated: November 24, 2025")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                        .padding(.bottom, 16)

                    // Business Information
                    InfoSection(
                        title: "Business Operator",
                        content: "[To be filled] Individual business name or company name"
                    )

                    InfoSection(
                        title: "Operations Manager",
                        content: "Takanori Nakano"
                    )

                    InfoSection(
                        title: "Address",
                        content: """
                        [To be filled]
                        〒xxx-xxxx
                        Tokyo, Japan

                        Note: As this is currently a personal development project, an official office address is being prepared.
                        Please contact us via email for inquiries.
                        """
                    )

                    InfoSection(
                        title: "Contact Information",
                        content: """
                        Email: support@globe-app.com
                        Business Hours: Weekdays 10:00-18:00 (JST)
                        """
                    )

                    InfoSection(
                        title: "Pricing",
                        content: """
                        GLOBE is currently completely free to use.

                        If we introduce paid plans in the future, we will announce them in advance and display a price list.
                        """
                    )

                    InfoSection(
                        title: "Additional Fees",
                        content: """
                        • Internet connection fees
                        • Communication fees (as defined by your carrier)

                        Note: Communication costs associated with app usage are borne by the user.
                        """
                    )

                    InfoSection(
                        title: "Payment Methods",
                        content: """
                        Currently, there are no payment features.

                        If implemented in the future:
                        • Apple App Store payments
                        • Credit card payments
                        • Other payment methods provided by Apple
                        """
                    )

                    InfoSection(
                        title: "Service Delivery",
                        content: """
                        Available immediately after account registration.

                        For paid plan purchases (future implementation):
                        Upgraded immediately after payment completion.
                        """
                    )

                    InfoSection(
                        title: "Returns & Cancellations",
                        content: """
                        【For Free Service】
                        You can delete your account at any time.
                        Settings > Account Settings > Delete Account

                        【For Paid Service (Future Implementation)】
                        Due to the nature of digital content, refunds and cancellations are not generally available.

                        However, we will process refunds in the following cases:
                        • Service was unavailable due to system failure
                        • Clear errors such as double billing occurred

                        Refund requests: support@globe-app.com
                        """
                    )

                    InfoSection(
                        title: "Operating Environment",
                        content: """
                        【Supported OS】
                        iOS 16.0 or later

                        【Supported Devices】
                        iPhone (Recommended: iPhone 12 or later)

                        【Required Permissions】
                        • Location Services (Required for posting)
                        • Camera (For photo posts only)
                        • Photo Library (For photo posts only)
                        """
                    )

                    InfoSection(
                        title: "Disclaimer",
                        content: """
                        • We are not responsible for any damages caused by service interruptions, termination, or changes
                        • Users are responsible for resolving disputes between users
                        • We are not liable for damages caused by force majeure such as natural disasters, war, or riots
                        """
                    )

                    InfoSection(
                        title: "Governing Law & Jurisdiction",
                        content: """
                        【Governing Law】
                        Japanese Law

                        【Jurisdiction】
                        Tokyo District Court shall be the exclusive court of first instance.
                        """
                    )

                    // Notice
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Important Notice")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(MinimalDesign.Colors.accentRed)

                        Text("""
                        This app is currently operated as a personal development project.

                        Official business registration or incorporation is planned, and this information will be updated at that time.

                        For questions, please contact support@globe-app.com
                        """)
                            .font(.system(size: 14))
                            .foregroundColor(MinimalDesign.Colors.textSecondary)
                            .padding()
                            .background(MinimalDesign.Colors.secondaryBackground)
                            .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Commercial Transactions")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct InfoSection: View {
    let title: String
    let content: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(MinimalDesign.Colors.text)

            Text(content)
                .font(.system(size: 15))
                .foregroundColor(MinimalDesign.Colors.textSecondary)
                .lineSpacing(4)
        }
        .padding()
        .background(MinimalDesign.Colors.secondaryBackground)
        .cornerRadius(8)
    }
}

#Preview {
    NavigationStack {
        CommercialTransactionsView()
    }
}
