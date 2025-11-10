//======================================================================
// MARK: - AuthServiceProtocol.swift
// Purpose: Authentication service protocol for dependency injection
// Path: GLOBE/Core/Protocols/AuthServiceProtocol.swift
//======================================================================

import Foundation
import Combine

protocol AuthServiceProtocol: ObservableObject {
    // MARK: - Published Properties
    var isAuthenticated: Bool { get }
    var currentUser: AppUser? { get set }
    var isAuthenticatedPublisher: AnyPublisher<Bool, Never> { get }

    // MARK: - Authentication Methods
    func signIn(email: String, password: String) async throws
    func signUp(email: String, password: String, displayName: String) async throws
    func signOut() async
    func checkCurrentUser() async -> Bool
    func validateSession() async throws -> Bool

    // MARK: - Security Methods
    func getDeviceSecurityInfo() -> [String: Any]
    func reportSecurityEvent(_ event: String, severity: SecuritySeverity, details: [String: String])

    // MARK: - Rate Limiting
    func checkRateLimit(for operation: String) -> Bool
}

// MARK: - Default Implementation
extension AuthServiceProtocol {
    func reportSecurityEvent(_ event: String, severity: SecuritySeverity = .medium, details: [String: String] = [:]) {
        SecureLogger.shared.securityEvent(event, details: details)
    }

    func checkRateLimit(for operation: String) -> Bool {
        // Default implementation - can be overridden
        return true
    }
}
