//======================================================================
// MARK: - AppleSignInCoordinator.swift
// Purpose: Coordinator for handling Apple Sign In flow
// Path: GLOBE/ViewModels/AppleSignInCoordinator.swift
//======================================================================

import Foundation
import AuthenticationServices
import UIKit

class AppleSignInCoordinator: NSObject, ASAuthorizationControllerDelegate, ASAuthorizationControllerPresentationContextProviding {
    private let nonce: String
    private let onSuccess: (String, String?) -> Void
    private let onFailure: (Error) -> Void

    init(nonce: String, onSuccess: @escaping (String, String?) -> Void, onFailure: @escaping (Error) -> Void) {
        self.nonce = nonce
        self.onSuccess = onSuccess
        self.onFailure = onFailure
    }

    // MARK: - ASAuthorizationControllerDelegate

    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            onFailure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid credential type"]))
            return
        }

        guard let identityTokenData = appleIDCredential.identityToken,
              let idTokenString = String(data: identityTokenData, encoding: .utf8) else {
            onFailure(NSError(domain: "AppleSignIn", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch identity token"]))
            return
        }

        // Get display name if available (only on first sign in)
        var displayName: String?
        if let fullName = appleIDCredential.fullName {
            let formatter = PersonNameComponentsFormatter()
            displayName = formatter.string(from: fullName)
        }

        onSuccess(idTokenString, displayName)
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        onFailure(error)
    }

    // MARK: - ASAuthorizationControllerPresentationContextProviding

    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = scene.windows.first else {
            fatalError("No window available")
        }
        return window
    }
}
