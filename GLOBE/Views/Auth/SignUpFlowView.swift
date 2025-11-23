//======================================================================
// MARK: - SignUpFlowView.swift
// Purpose: Multi-step sign up flow (Email → Username → Display Name)
// Path: GLOBE/Views/Auth/SignUpFlowView.swift
//======================================================================

import SwiftUI

struct SignUpFlowView: View {
    @Environment(\.dismiss) var dismiss
    @State private var currentStep: SignUpStep = .emailPassword
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var displayName = ""

    enum SignUpStep {
        case emailPassword
        case username
        case displayName
    }

    var body: some View {
        ZStack {
            MinimalDesign.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with close button
                HStack {
                    Button(action: {
                        if currentStep == .emailPassword {
                            dismiss()
                        } else {
                            // Go back to previous step
                            withAnimation {
                                switch currentStep {
                                case .username:
                                    currentStep = .emailPassword
                                case .displayName:
                                    currentStep = .username
                                default:
                                    break
                                }
                            }
                        }
                    }) {
                        Image(systemName: currentStep == .emailPassword ? "xmark" : "chevron.left")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
                    }
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 60)
                .padding(.bottom, 20)

                // Progress indicator
                HStack(spacing: 8) {
                    ForEach([SignUpStep.emailPassword, .username, .displayName], id: \.self) { step in
                        Rectangle()
                            .fill(currentStep.rawValue >= step.rawValue ? Color.white : Color.white.opacity(0.3))
                            .frame(height: 3)
                            .cornerRadius(1.5)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)

                // Content based on current step
                Group {
                    switch currentStep {
                    case .emailPassword:
                        EmailPasswordStepView(
                            email: $email,
                            password: $password,
                            onNext: {
                                withAnimation {
                                    currentStep = .username
                                }
                            }
                        )
                    case .username:
                        UsernameStepView(
                            username: $username,
                            onNext: {
                                withAnimation {
                                    currentStep = .displayName
                                }
                            }
                        )
                    case .displayName:
                        DisplayNameStepView(
                            email: email,
                            password: password,
                            username: username,
                            displayName: $displayName,
                            onComplete: {
                                dismiss()
                            }
                        )
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)
                ))

                Spacer()
            }
        }
    }
}

extension SignUpFlowView.SignUpStep: Comparable {
    var rawValue: Int {
        switch self {
        case .emailPassword: return 0
        case .username: return 1
        case .displayName: return 2
        }
    }

    static func < (lhs: SignUpFlowView.SignUpStep, rhs: SignUpFlowView.SignUpStep) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

#Preview {
    SignUpFlowView()
}
