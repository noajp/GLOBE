//======================================================================
// MARK: - CertificatePinning.swift
// Purpose: Certificate pinning implementation for enhanced network security
// Path: GLOBE/Core/Security/CertificatePinning.swift
//======================================================================

import Foundation
import Network
import CryptoKit

@MainActor
final class CertificatePinning: NSObject {

    static let shared = CertificatePinning()

    private override init() {
        super.init()
        setupNetworkPathMonitor()
    }

    // MARK: - Configuration

    /// Pinned certificate hashes (SHA-256) for Supabase domains
    private let pinnedCertificateHashes: [String: Set<String>] = [
        "supabase.co": [
            // Primary Supabase certificate hash (example - should be updated with real values)
            "B8C1A8AC1B2C5A8F9D3E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C",
            // Backup certificate hash for rotation
            "C9D2B9BD2C3D6B9F0E4F5A6B7C8D9E0F1A2B3C4D5E6F7A8B9C0D1E2F3A4B5C6"
        ]
    ]

    /// Public key hashes (SHA-256) for additional verification
    private let pinnedPublicKeyHashes: [String: Set<String>] = [
        "supabase.co": [
            "D4E5F6A7B8C9D0E1F2A3B4C5D6E7F8A9B0C1D2E3F4A5B6C7D8E9F0A1B2C3D4",
            "E5F6A7B8C9D0E1F2A3B4C5D6E7F8A9B0C1D2E3F4A5B6C7D8E9F0A1B2C3D4E5"
        ]
    ]

    /// Configuration for certificate validation
    private struct PinningConfiguration {
        let enableCertificatePinning: Bool
        let enablePublicKeyPinning: Bool
        let allowDevelopmentCertificates: Bool
        let enforceExpirationCheck: Bool
        let requireCompleteChainValidation: Bool

        static let production = PinningConfiguration(
            enableCertificatePinning: true,
            enablePublicKeyPinning: true,
            allowDevelopmentCertificates: false,
            enforceExpirationCheck: true,
            requireCompleteChainValidation: true
        )

        static let development = PinningConfiguration(
            enableCertificatePinning: false,
            enablePublicKeyPinning: false,
            allowDevelopmentCertificates: true,
            enforceExpirationCheck: false,
            requireCompleteChainValidation: false
        )
    }

    private var configuration: PinningConfiguration {
        #if DEBUG
        return .development
        #else
        return .production
        #endif
    }

    // MARK: - Network Path Monitoring

    private let pathMonitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "certificate.pinning.monitor")
    private var isNetworkAvailable = true

    private func setupNetworkPathMonitor() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor in
                self?.isNetworkAvailable = path.status == .satisfied
                if path.status != .satisfied {
                    SecureLogger.shared.warning("Network unavailable - certificate pinning may be affected")
                }
            }
        }
        pathMonitor.start(queue: monitorQueue)
    }

    // MARK: - URLSessionDelegate Integration

    /// Validate server trust with certificate pinning
    func validateServerTrust(
        _ serverTrust: SecTrust,
        for host: String,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        guard configuration.enableCertificatePinning || configuration.enablePublicKeyPinning else {
            // In development mode, use default validation
            let result = SecTrustEvaluateWithError(serverTrust, nil)
            if result {
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                SecureLogger.shared.error("Default certificate validation failed for \(host)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
            return
        }

        // Perform certificate pinning validation
        Task {
            let isValid = await validateCertificateChain(serverTrust, for: host)

            if isValid {
                SecureLogger.shared.info("Certificate pinning validation succeeded for \(host)")
                completionHandler(.useCredential, URLCredential(trust: serverTrust))
            } else {
                SecureLogger.shared.error("Certificate pinning validation failed for \(host)")
                completionHandler(.cancelAuthenticationChallenge, nil)
            }
        }
    }

    // MARK: - Certificate Validation

    private func validateCertificateChain(_ serverTrust: SecTrust, for host: String) async -> Bool {

        // Extract domain from host
        let domain = extractDomain(from: host)

        // Check if we have pinned certificates for this domain
        guard pinnedCertificateHashes[domain] != nil || pinnedPublicKeyHashes[domain] != nil else {
            SecureLogger.shared.warning("No pinned certificates found for domain: \(domain)")
            // Fall back to system validation for unpinned domains
            return performSystemValidation(serverTrust)
        }

        // Get certificate chain
        guard let certificateChain = getCertificateChain(from: serverTrust) else {
            SecureLogger.shared.error("Failed to extract certificate chain")
            return false
        }

        // Perform basic trust evaluation first
        if configuration.requireCompleteChainValidation {
            var result: CFError?
            let trustResult = SecTrustEvaluateWithError(serverTrust, &result)

            if !trustResult {
                SecureLogger.shared.error("System trust evaluation failed: \(result?.localizedDescription ?? "Unknown error")")

                if !configuration.allowDevelopmentCertificates {
                    return false
                }
            }
        }

        // Validate certificate pinning
        if configuration.enableCertificatePinning {
            let certificateValidation = await validateCertificates(certificateChain, for: domain)
            if certificateValidation {
                return true
            }
        }

        // Validate public key pinning
        if configuration.enablePublicKeyPinning {
            let publicKeyValidation = await validatePublicKeys(certificateChain, for: domain)
            if publicKeyValidation {
                return true
            }
        }

        return false
    }

    private func getCertificateChain(from serverTrust: SecTrust) -> [SecCertificate]? {
        let certificateCount = SecTrustGetCertificateCount(serverTrust)
        guard certificateCount > 0 else { return nil }

        var certificates: [SecCertificate] = []
        for index in 0..<certificateCount {
            if let certificate = SecTrustGetCertificateAtIndex(serverTrust, index) {
                certificates.append(certificate)
            }
        }

        return certificates.isEmpty ? nil : certificates
    }

    private func validateCertificates(_ certificates: [SecCertificate], for domain: String) async -> Bool {
        guard let pinnedHashes = pinnedCertificateHashes[domain] else { return false }

        for certificate in certificates {
            let certificateData = SecCertificateCopyData(certificate)
            let hash = SHA256.hash(data: certificateData as Data)
            let hashString = hash.compactMap { String(format: "%02X", $0) }.joined()

            if pinnedHashes.contains(hashString) {
                SecureLogger.shared.info("Certificate hash matched for domain: \(domain)")
                return true
            }
        }

        SecureLogger.shared.error("No certificate hash matches found for domain: \(domain)")
        return false
    }

    private func validatePublicKeys(_ certificates: [SecCertificate], for domain: String) async -> Bool {
        guard let pinnedHashes = pinnedPublicKeyHashes[domain] else { return false }

        for certificate in certificates {
            guard let publicKey = extractPublicKey(from: certificate) else { continue }

            var error: Unmanaged<CFError>?
            guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, &error) else {
                SecureLogger.shared.error("Failed to extract public key data: \(error?.takeRetainedValue().localizedDescription ?? "Unknown")")
                continue
            }

            let hash = SHA256.hash(data: publicKeyData as Data)
            let hashString = hash.compactMap { String(format: "%02X", $0) }.joined()

            if pinnedHashes.contains(hashString) {
                SecureLogger.shared.info("Public key hash matched for domain: \(domain)")
                return true
            }
        }

        SecureLogger.shared.error("No public key hash matches found for domain: \(domain)")
        return false
    }

    private func extractPublicKey(from certificate: SecCertificate) -> SecKey? {
        let policy = SecPolicyCreateSSL(true, nil)
        var trust: SecTrust?

        let status = SecTrustCreateWithCertificates(certificate, policy, &trust)
        guard status == errSecSuccess, let trust = trust else {
            return nil
        }

        return SecTrustCopyPublicKey(trust)
    }

    private func performSystemValidation(_ serverTrust: SecTrust) -> Bool {
        var result: CFError?
        return SecTrustEvaluateWithError(serverTrust, &result)
    }

    // MARK: - Helper Methods

    private func extractDomain(from host: String) -> String {
        // Remove port number if present
        let hostWithoutPort = host.components(separatedBy: ":").first ?? host

        // Extract main domain (e.g., "api.supabase.co" -> "supabase.co")
        let components = hostWithoutPort.components(separatedBy: ".")
        if components.count >= 2 {
            return components.suffix(2).joined(separator: ".")
        }

        return hostWithoutPort
    }

    // MARK: - Certificate Management

    /// Update pinned certificates (for certificate rotation)
    func updatePinnedCertificates(for domain: String, certificateHashes: Set<String>) {
        // In production, this should be done through a secure update mechanism
        // For now, log the update attempt
        SecureLogger.shared.info("Certificate update requested for domain: \(domain)")

        #if DEBUG
        SecureLogger.shared.warning("Certificate pinning update attempted in development mode")
        #endif
    }

    /// Validate certificate expiration dates
    func validateCertificateExpiration(_ certificates: [SecCertificate]) -> Bool {
        guard configuration.enforceExpirationCheck else { return true }

        let currentDate = Date()

        for certificate in certificates {
            var commonName: CFString?
            SecCertificateCopyCommonName(certificate, &commonName)
            let name = commonName as String? ?? "Unknown"

            // Check not valid before
            if let notValidBefore = getCertificateDate(certificate, property: kSecOIDX509V1ValidityNotBefore) {
                if currentDate < notValidBefore {
                    SecureLogger.shared.error("Certificate \(name) is not yet valid")
                    return false
                }
            }

            // Check not valid after
            if let notValidAfter = getCertificateDate(certificate, property: kSecOIDX509V1ValidityNotAfter) {
                if currentDate > notValidAfter {
                    SecureLogger.shared.error("Certificate \(name) has expired")
                    return false
                }

                // Check if certificate expires soon (within 30 days)
                let thirtyDaysFromNow = currentDate.addingTimeInterval(30 * 24 * 60 * 60)
                if thirtyDaysFromNow > notValidAfter {
                    SecureLogger.shared.warning("Certificate \(name) expires soon: \(notValidAfter)")
                }
            }
        }

        return true
    }

    private func getCertificateDate(_ certificate: SecCertificate, property: CFString) -> Date? {
        guard let values = SecCertificateCopyValues(certificate, [property], nil) as? [CFString: Any],
              let dateDict = values[property] as? [CFString: Any],
              let dateValue = dateDict[kSecPropertyKeyValue] as? CFAbsoluteTime else {
            return nil
        }

        return Date(timeIntervalSinceReferenceDate: dateValue)
    }

    // MARK: - Security Reporting

    /// Report certificate pinning failures for security monitoring
    private func reportPinningFailure(host: String, reason: String) {
        let report = [
            "event": "certificate_pinning_failure",
            "host": host,
            "reason": reason,
            "timestamp": ISO8601DateFormatter().string(from: Date()),
            "network_available": isNetworkAvailable
        ]

        SecureLogger.shared.critical("Certificate pinning failure: \(report)")

        // In production, this could be sent to a security monitoring service
        #if DEBUG
        print("🚨 Certificate Pinning Failure Report: \(report)")
        #endif
    }

    deinit {
        pathMonitor.cancel()
    }
}

// MARK: - URLSessionDelegate Extension

extension CertificatePinning: URLSessionDelegate {

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {

        // Only handle server trust challenges
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
            completionHandler(.performDefaultHandling, nil)
            return
        }

        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            SecureLogger.shared.error("No server trust available for challenge")
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }

        let host = challenge.protectionSpace.host
        validateServerTrust(serverTrust, for: host, completionHandler: completionHandler)
    }
}

// MARK: - Secure URLSession Factory

extension CertificatePinning {

    /// Create URLSession with certificate pinning enabled
    nonisolated static func createSecureURLSession(
        configuration: URLSessionConfiguration = .default,
        delegateQueue: OperationQueue? = nil
    ) -> URLSession {

        // Configure security settings
        configuration.tlsMinimumSupportedProtocolVersion = .TLSv12
        configuration.tlsMaximumSupportedProtocolVersion = .TLSv13

        // Disable caching for sensitive requests
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData

        // Configure timeouts
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60

        return URLSession(
            configuration: configuration,
            delegate: CertificatePinning.shared,
            delegateQueue: delegateQueue
        )
    }
}