//======================================================================
// MARK: - ContentModerationPolicyView.swift
// Purpose: Content moderation policy for provider liability compliance
// Path: GLOBE/Views/Settings/Legal/ContentModerationPolicyView.swift
//======================================================================
import SwiftUI

struct ContentModerationPolicyView: View {
    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Content Moderation Policy")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(MinimalDesign.Colors.text)
                        .padding(.bottom, 8)

                    Text("Last Updated: November 24, 2025")
                        .font(.system(size: 14))
                        .foregroundColor(MinimalDesign.Colors.textSecondary)
                        .padding(.bottom, 16)

                    // Provider Liability Compliance
                    SectionView(
                        title: "1. Policy for Illegal & Harmful Content",
                        content: """
                        GLOBE operates in accordance with the Provider Liability Limitation Act, with the following policies:

                        • Illegal or harmful content will be removed promptly upon discovery
                        • User reports will be reviewed within 24 hours
                        • We respond to rights infringement claims
                        • We comply with legal requests for sender information disclosure
                        """
                    )

                    SectionView(
                        title: "2. Content Subject to Removal",
                        content: """
                        The following content will be removed upon discovery:

                        【Illegal Content】
                        • Posts promoting or inciting criminal activity
                        • Child pornography or child abuse content
                        • Posts related to drugs or dangerous substances
                        • Fraud or money laundering content
                        • Posts praising or inciting terrorism

                        【Rights Infringement】
                        • Infringement of copyright, trademarks, or portrait rights
                        • Invasion of privacy
                        • Defamation or insults

                        【Harmful Content】
                        • Violent or cruel content
                        • Discrimination or hate speech
                        • Harassment or bullying
                        • Sexual content
                        • Content promoting self-harm or suicide
                        """
                    )

                    SectionView(
                        title: "3. Report to Removal Process",
                        content: """
                        【Report Reception】
                        1. Accept reports via in-app button or email (abuse@globe-app.com)
                        2. Record and store report details

                        【Review Process】
                        3. Specialist team begins review within 24 hours
                        4. Compare against Community Guidelines and laws
                        5. Consult external experts (lawyers, etc.) if necessary

                        【Removal Decision】
                        6. Remove immediately if violation confirmed
                        7. Notify poster of removal reason
                        8. Store removal record for 90 days

                        【Appeal】
                        9. Removed posters can appeal within 7 days
                        10. Re-review and respond within 7 days
                        """
                    )

                    SectionView(
                        title: "4. Sender Information Disclosure",
                        content: """
                        We respond to sender information disclosure requests under Provider Liability Limitation Act Article 4.

                        【Disclosure Requirements】
                        • Clear evidence of rights infringement
                        • Legitimate reason
                        • Court order or subject consent

                        【Information Disclosed】
                        • Sender's IP address
                        • Timestamp
                        • Email address (account information)
                        • Other information ordered by court

                        【Disclosure Process】
                        1. Receive request (written or court order)
                        2. Verify and record request
                        3. Solicit sender's opinion (7 days)
                        4. Decide on disclosure
                        5. Execute disclosure or send rejection notice

                        【Contact】
                        Disclosure requests: legal@globe-app.com
                        """
                    )

                    SectionView(
                        title: "5. Removal Record Storage",
                        content: """
                        The following information is stored for 90 days:

                        • Screenshot of removed content
                        • Removal date/time
                        • Removal reason
                        • Reporter information (anonymized)
                        • Notification record to poster

                        Securely deleted after retention period.
                        """
                    )

                    SectionView(
                        title: "6. Account Suspension",
                        content: """
                        Serious or repeated violations result in account suspension.

                        【Warning】
                        First minor violation → Warning notification

                        【Temporary Suspension】
                        Second violation or moderate violation → 3-30 day suspension

                        【Permanent Ban】
                        • 3 or more violations
                        • Serious violations (illegal activity, rights infringement)
                        • Re-violation during suspension

                        Appeals are accepted for suspension measures.
                        """
                    )

                    SectionView(
                        title: "7. Reporter Protection",
                        content: """
                        • Reporter information is strictly protected
                        • Careful consideration to prevent reporter identification
                        • False reports and abuse will be strictly addressed
                        """
                    )

                    SectionView(
                        title: "8. Transparency Report",
                        content: """
                        Published quarterly:

                        • Number of reports received
                        • Number of removed content (by category)
                        • Number of account suspensions
                        • Sender information disclosure requests and disclosures
                        """
                    )

                    SectionView(
                        title: "9. Contact Information",
                        content: """
                        【General Reports】
                        abuse@globe-app.com

                        【Rights Infringement Claims】
                        copyright@globe-app.com

                        【Sender Information Disclosure】
                        legal@globe-app.com

                        【Office Address】
                        〒xxx-xxxx
                        Tokyo, Japan
                        (Official office address to be listed)

                        【Operating Company】
                        GLOBE Operations Office
                        """
                    )
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
        }
        .navigationTitle("Moderation Policy")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        ContentModerationPolicyView()
    }
}
