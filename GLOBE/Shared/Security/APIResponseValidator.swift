//======================================================================
// MARK: - APIResponseValidator.swift
// Purpose: Enhanced API response validation for security and data integrity
// Path: GLOBE/Core/Security/APIResponseValidator.swift
//======================================================================

import Foundation
import CryptoKit

@MainActor
final class APIResponseValidator {

    static let shared = APIResponseValidator()

    private init() {}

    // MARK: - Response Validation Configuration

    private struct ValidationConfig {
        let maxResponseSize: Int = 10 * 1024 * 1024 // 10MB
        let maxStringLength: Int = 10000
        let maxArraySize: Int = 1000
        let requireHTTPS: Bool = true
        let validateContentType: Bool = true
        let checkResponseIntegrity: Bool = true
        let validateTimestamp: Bool = true
        let maxResponseAge: TimeInterval = 300 // 5 minutes
    }

    private let config = ValidationConfig()

    // MARK: - Response Size Validation

    /// Validate response size before processing
    func validateResponseSize(_ data: Data?, response: URLResponse?) throws {
        guard let data = data else {
            throw ValidationError.emptyResponse
        }

        if data.count > config.maxResponseSize {
            SecureLogger.shared.error("Response size exceeds maximum allowed: \(data.count) bytes")
            throw ValidationError.responseTooLarge(size: data.count)
        }

        // Check if response appears to be a zip bomb or similar
        if let httpResponse = response as? HTTPURLResponse,
           let contentLength = httpResponse.allHeaderFields["Content-Length"] as? String,
           let expectedLength = Int(contentLength),
           data.count != expectedLength {
            SecureLogger.shared.warning("Response size mismatch: expected \(expectedLength), got \(data.count)")
        }
    }

    // MARK: - Content Type Validation

    /// Validate response content type
    func validateContentType(_ response: URLResponse?, expectedTypes: [String] = ["application/json"]) throws {
        guard config.validateContentType else { return }

        guard let httpResponse = response as? HTTPURLResponse,
              let contentType = httpResponse.mimeType else {
            throw ValidationError.invalidContentType(received: "unknown")
        }

        let isValidType = expectedTypes.contains { expectedType in
            contentType.lowercased().contains(expectedType.lowercased())
        }

        guard isValidType else {
            SecureLogger.shared.error("Invalid content type: expected \(expectedTypes), got \(contentType)")
            throw ValidationError.invalidContentType(received: contentType)
        }
    }

    // MARK: - HTTPS Validation

    /// Validate that response came over HTTPS
    func validateHTTPS(_ response: URLResponse?) throws {
        guard config.requireHTTPS else { return }

        guard let httpResponse = response as? HTTPURLResponse,
              let url = httpResponse.url,
              url.scheme?.lowercased() == "https" else {
            SecureLogger.shared.error("Response not received over HTTPS")
            throw ValidationError.insecureConnection
        }
    }

    // MARK: - JSON Structure Validation

    /// Validate JSON structure and content
    func validateJSONStructure<T: Codable>(_ data: Data, as type: T.Type) throws -> T {
        // First, validate as generic JSON
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) else {
            throw ValidationError.invalidJSONFormat
        }

        // Validate structure depth and size
        try validateJSONObjectStructure(jsonObject)

        // Decode to specific type with validation
        let decoder = createSecureJSONDecoder()
        do {
            return try decoder.decode(type, from: data)
        } catch {
            SecureLogger.shared.error("Failed to decode JSON to \(type): \(error)")
            throw ValidationError.jsonDecodingFailed(error: error)
        }
    }

    /// Validate generic JSON object structure
    private func validateJSONObjectStructure(_ object: Any, depth: Int = 0) throws {
        // Prevent deeply nested structures (potential DoS)
        guard depth < 20 else {
            throw ValidationError.jsonTooDeep
        }

        switch object {
        case let dictionary as [String: Any]:
            // Validate dictionary size
            guard dictionary.count <= config.maxArraySize else {
                throw ValidationError.jsonTooLarge
            }

            // Validate keys
            for (key, value) in dictionary {
                try validateStringContent(key)
                try validateJSONObjectStructure(value, depth: depth + 1)
            }

        case let array as [Any]:
            // Validate array size
            guard array.count <= config.maxArraySize else {
                throw ValidationError.jsonTooLarge
            }

            // Validate elements
            for element in array {
                try validateJSONObjectStructure(element, depth: depth + 1)
            }

        case let string as String:
            try validateStringContent(string)

        case is NSNumber, is Bool, is NSNull:
            // These types are safe
            break

        default:
            // Unknown type - potentially unsafe
            throw ValidationError.unsupportedDataType
        }
    }

    // MARK: - String Content Validation

    /// Validate string content for security issues
    private func validateStringContent(_ string: String) throws {
        // Check length
        guard string.count <= config.maxStringLength else {
            throw ValidationError.stringTooLong(length: string.count)
        }

        // Check for null bytes (potential injection)
        guard !string.contains("\0") else {
            throw ValidationError.invalidCharacters
        }

        // Check for potential script injection patterns
        let suspiciousPatterns = [
            "<script",
            "javascript:",
            "data:text/html",
            "vbscript:",
            "onload=",
            "onclick=",
            "eval(",
            "setTimeout(",
            "setInterval("
        ]

        let lowercaseString = string.lowercased()
        for pattern in suspiciousPatterns {
            if lowercaseString.contains(pattern) {
                SecureLogger.shared.warning("Suspicious content detected in string: \(pattern)")
                throw ValidationError.suspiciousContent(pattern: pattern)
            }
        }
    }

    // MARK: - Response Integrity Validation

    /// Validate response integrity using checksums or signatures
    func validateResponseIntegrity(
        _ data: Data,
        expectedChecksum: String? = nil,
        signature: String? = nil,
        publicKey: String? = nil
    ) throws {
        guard config.checkResponseIntegrity else { return }

        // Validate checksum if provided
        if let expectedChecksum = expectedChecksum {
            let actualChecksum = SHA256.hash(data: data)
            let actualChecksumString = actualChecksum.compactMap { String(format: "%02x", $0) }.joined()

            guard actualChecksumString == expectedChecksum.lowercased() else {
                SecureLogger.shared.error("Response checksum mismatch")
                throw ValidationError.checksumMismatch
            }
        }

        // Validate signature if provided (placeholder for future implementation)
        if let _ = signature, let _ = publicKey {
            // This would implement signature verification using the public key
            // For now, just log that signature verification was requested
            SecureLogger.shared.info("Signature verification requested but not yet implemented")
        }
    }

    // MARK: - Timestamp Validation

    /// Validate response timestamp to prevent replay attacks
    func validateResponseTimestamp(_ response: URLResponse?) throws {
        guard config.validateTimestamp else { return }

        guard let httpResponse = response as? HTTPURLResponse else { return }

        // Check Date header
        if let dateString = httpResponse.allHeaderFields["Date"] as? String {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss zzz"
            formatter.locale = Locale(identifier: "en_US_POSIX")
            formatter.timeZone = TimeZone(abbreviation: "GMT")

            if let responseDate = formatter.date(from: dateString) {
                let age = Date().timeIntervalSince(responseDate)

                if age > config.maxResponseAge {
                    SecureLogger.shared.warning("Response is too old: \(age) seconds")
                    throw ValidationError.responseExpired(age: age)
                }

                if age < -60 { // Allow 1 minute clock skew
                    SecureLogger.shared.warning("Response from future: \(-age) seconds")
                    throw ValidationError.responseFromFuture
                }
            }
        }
    }

    // MARK: - Secure JSON Decoder

    private func createSecureJSONDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()

        // Configure date decoding strategy
        decoder.dateDecodingStrategy = .iso8601

        // Configure data decoding strategy
        decoder.dataDecodingStrategy = .base64

        // Configure key decoding strategy
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        return decoder
    }

    // MARK: - Comprehensive Response Validation

    /// Perform comprehensive validation of API response
    func validateAPIResponse<T: Codable>(
        data: Data?,
        response: URLResponse?,
        expectedType: T.Type,
        expectedChecksum: String? = nil,
        expectedContentTypes: [String] = ["application/json"]
    ) throws -> T {

        // Step 1: Validate HTTPS
        try validateHTTPS(response)

        // Step 2: Validate response size
        try validateResponseSize(data, response: response)

        // Step 3: Validate content type
        try validateContentType(response, expectedTypes: expectedContentTypes)

        // Step 4: Validate timestamp
        try validateResponseTimestamp(response)

        // Step 5: Get validated data
        guard let data = data else {
            throw ValidationError.emptyResponse
        }

        // Step 6: Validate integrity
        try validateResponseIntegrity(data, expectedChecksum: expectedChecksum)

        // Step 7: Validate and decode JSON structure
        let decodedObject = try validateJSONStructure(data, as: expectedType)

        SecureLogger.shared.info("API response validation completed successfully")
        return decodedObject
    }

    // MARK: - Security Headers Validation

    /// Validate security headers in HTTP response
    func validateSecurityHeaders(_ response: URLResponse?) throws {
        guard let httpResponse = response as? HTTPURLResponse else { return }

        let headers = httpResponse.allHeaderFields
        var warnings: [String] = []

        // Check for security headers
        let securityHeaders = [
            "Strict-Transport-Security": "HSTS header missing",
            "Content-Security-Policy": "CSP header missing",
            "X-Content-Type-Options": "X-Content-Type-Options header missing",
            "X-Frame-Options": "X-Frame-Options header missing",
            "X-XSS-Protection": "X-XSS-Protection header missing"
        ]

        for (header, warning) in securityHeaders {
            if headers[header] == nil {
                warnings.append(warning)
            }
        }

        // Check for potentially dangerous headers
        if let serverHeader = headers["Server"] as? String {
            if serverHeader.contains("Apache") || serverHeader.contains("nginx") {
                warnings.append("Server version information exposed")
            }
        }

        if let poweredBy = headers["X-Powered-By"] as? String {
            warnings.append("X-Powered-By header exposes technology stack: \(poweredBy)")
        }

        // Log warnings but don't fail validation
        for warning in warnings {
            SecureLogger.shared.warning("Security header issue: \(warning)")
        }
    }
}

// MARK: - ValidationError

enum ValidationError: Error, LocalizedError {
    case emptyResponse
    case responseTooLarge(size: Int)
    case invalidContentType(received: String)
    case insecureConnection
    case invalidJSONFormat
    case jsonDecodingFailed(error: Error)
    case jsonTooDeep
    case jsonTooLarge
    case stringTooLong(length: Int)
    case invalidCharacters
    case suspiciousContent(pattern: String)
    case unsupportedDataType
    case checksumMismatch
    case responseExpired(age: TimeInterval)
    case responseFromFuture

    var errorDescription: String? {
        switch self {
        case .emptyResponse:
            return "Response is empty"
        case .responseTooLarge(let size):
            return "Response size too large: \(size) bytes"
        case .invalidContentType(let received):
            return "Invalid content type: \(received)"
        case .insecureConnection:
            return "Response not received over secure connection"
        case .invalidJSONFormat:
            return "Invalid JSON format"
        case .jsonDecodingFailed(let error):
            return "JSON decoding failed: \(error.localizedDescription)"
        case .jsonTooDeep:
            return "JSON structure too deeply nested"
        case .jsonTooLarge:
            return "JSON structure too large"
        case .stringTooLong(let length):
            return "String too long: \(length) characters"
        case .invalidCharacters:
            return "String contains invalid characters"
        case .suspiciousContent(let pattern):
            return "Suspicious content detected: \(pattern)"
        case .unsupportedDataType:
            return "Unsupported data type in JSON"
        case .checksumMismatch:
            return "Response integrity check failed"
        case .responseExpired(let age):
            return "Response expired: \(age) seconds old"
        case .responseFromFuture:
            return "Response timestamp is from the future"
        }
    }
}

// MARK: - Secure Network Service Extension

extension APIResponseValidator {

    /// Create a secure data task with built-in validation
    func createSecureDataTask(
        with request: URLRequest,
        session: URLSession? = nil,
        expectedChecksum: String? = nil
    ) -> SecureDataTask {
        let actualSession = session ?? URLSession(configuration: .default)
        return SecureDataTask(
            request: request,
            session: actualSession,
            validator: self,
            expectedChecksum: expectedChecksum
        )
    }
}

// MARK: - Secure Data Task

final class SecureDataTask {
    private let request: URLRequest
    private let session: URLSession
    private let validator: APIResponseValidator
    private let expectedChecksum: String?

    init(
        request: URLRequest,
        session: URLSession,
        validator: APIResponseValidator,
        expectedChecksum: String?
    ) {
        self.request = request
        self.session = session
        self.validator = validator
        self.expectedChecksum = expectedChecksum
    }

    /// Perform secure data task with automatic validation
    func perform<T: Codable & Sendable>(expecting type: T.Type) async throws -> T {
        return try await withCheckedThrowingContinuation { continuation in
            let task = session.dataTask(with: request) { [weak self] data, response, error in
                guard let self = self else {
                    continuation.resume(throwing: ValidationError.emptyResponse)
                    return
                }

                Task { @MainActor in
                    do {
                        if let error = error {
                            throw error
                        }

                        let validatedObject = try self.validator.validateAPIResponse(
                            data: data,
                            response: response,
                            expectedType: type,
                            expectedChecksum: self.expectedChecksum
                        )

                        // Additional security headers validation
                        try self.validator.validateSecurityHeaders(response)

                        continuation.resume(returning: validatedObject)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }

            task.resume()
        }
    }
}
