//======================================================================
// MARK: - SignUpFlowView.swift
// Purpose: Multi-step sign up flow (Email → OTP Verification → Password Setup)
// Path: GLOBE/Views/Auth/SignUpFlowView.swift
//======================================================================

import SwiftUI

struct SignUpFlowView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationStack {
            SignUpEmailView()
                .environmentObject(AuthManager.shared)
        }
    }
}

#Preview {
    SignUpFlowView()
}
