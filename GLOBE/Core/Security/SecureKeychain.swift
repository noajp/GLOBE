//======================================================================
// MARK: - SecureKeychain.swift
// Purpose: Enhanced Keychain wrapper with advanced security features
// Path: GLOBE/Core/Security/SecureKeychain.swift
//======================================================================

import Foundation
import Security
import CryptoKit

@MainActor
final class SecureKeychain {

    static let shared = SecureKeychain()

    private init() {}

    // MARK: - Security Configuration

    /// Keychain access group for shared data across app extensions
    private let accessGroup: String? = {
        guard let teamID = Bundle.main.object(forInfoDictionaryKey: "TeamIdentifierPrefix") as? String else {
            return nil
        }
        return "\(teamID)com.globe.keychain"
    }()

    /// Service identifier for Keychain items
    private let serviceIdentifier: String = {
        Bundle.main.bundleIdentifier ?? "com.globe.app"
    }()

    // MARK: - Keychain Item Types

    enum KeychainItemType {
        case generic(account: String)
        case internetPassword(server: String, account: String)
        case certificate(label: String)
        case key(applicationTag: String)

        var secClass: CFString {
            switch self {
            case .generic:
                return kSecClassGenericPassword
            case .internetPassword:
                return kSecClassInternetPassword
            case .certificate:
                return kSecClassCertificate
            case .key:
                return kSecClassKey
            }
        }
    }

    // MARK: - Security Access Control

    enum AccessControl {
        case whenUnlocked
        case whenUnlockedThisDeviceOnly
        case afterFirstUnlock
        case afterFirstUnlockThisDeviceOnly
        case whenPasscodeSetThisDeviceOnly
        case biometryAny
        case biometryCurrentSet

        var flags: SecAccessControlCreateFlags {
            switch self {
            case .whenUnlocked:
                return []
            case .whenUnlockedThisDeviceOnly:
                return [.devicePasscode]
            case .afterFirstUnlock:
                return []
            case .afterFirstUnlockThisDeviceOnly:
                return [.devicePasscode]
            case .whenPasscodeSetThisDeviceOnly:
                return [.devicePasscode]
            case .biometryAny:
                return [.biometryAny]
            case .biometryCurrentSet:
                return [.biometryCurrentSet]
            }
        }

        var accessibility: CFString {
            switch self {
            case .whenUnlocked:
                return kSecAttrAccessibleWhenUnlocked
            case .whenUnlockedThisDeviceOnly:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            case .afterFirstUnlock:
                return kSecAttrAccessibleAfterFirstUnlock
            case .afterFirstUnlockThisDeviceOnly:
                return kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
            case .whenPasscodeSetThisDeviceOnly:
                return kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly
            case .biometryAny, .biometryCurrentSet:
                return kSecAttrAccessibleWhenUnlockedThisDeviceOnly
            }
        }
    }

    // MARK: - Enhanced Storage Methods

    /// Store sensitive data with encryption and access control
    func store<T: Codable>(
        _ data: T,
        for key: String,
        itemType: KeychainItemType = .generic(account: ""),
        accessControl: AccessControl = .whenUnlockedThisDeviceOnly,
        requireBiometry: Bool = false
    ) throws {

        // Encode data
        let encodedData: Data
        do {
            encodedData = try JSONEncoder().encode(data)
        } catch {
            SecureLogger.shared.error("Failed to encode data for key \(key): \(error)")
            throw KeychainError.encodingFailed
        }

        // Encrypt data
        let encryptedData: Data
        do {
            encryptedData = try encryptData(encodedData, for: key)
        } catch {
            SecureLogger.shared.error("Failed to encrypt data for key \(key): \(error)")
            throw KeychainError.encryptionFailed
        }

        // Create access control
        var accessControlRef: SecAccessControl?
        if requireBiometry || accessControl == .biometryAny || accessControl == .biometryCurrentSet {
            var error: Unmanaged<CFError>?
            accessControlRef = SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                accessControl.accessibility,
                accessControl.flags,
                &error
            )

            if let error = error?.takeRetainedValue() {
                SecureLogger.shared.error("Failed to create access control: \(error)")
                throw KeychainError.accessControlFailed
            }
        }

        // Build query
        var query = buildBaseQuery(for: itemType, key: key)
        query[kSecValueData as String] = encryptedData
        query[kSecAttrAccessible as String] = accessControl.accessibility

        if let accessControlRef = accessControlRef {
            query[kSecAttrAccessControl as String] = accessControlRef
        }

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Store item
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecDuplicateItem {
            // Update existing item
            let updateQuery = buildBaseQuery(for: itemType, key: key)
            let updateAttributes: [String: Any] = [
                kSecValueData as String: encryptedData
            ]

            let updateStatus = SecItemUpdate(updateQuery as CFDictionary, updateAttributes as CFDictionary)
            if updateStatus != errSecSuccess {
                SecureLogger.shared.error("Failed to update keychain item \(key): \(updateStatus)")
                throw KeychainError.updateFailed(status: updateStatus)
            }
        } else if status != errSecSuccess {
            SecureLogger.shared.error("Failed to store keychain item \(key): \(status)")
            throw KeychainError.storeFailed(status: status)
        }

        SecureLogger.shared.info("Successfully stored encrypted item for key: \(key)")
    }

    /// Retrieve and decrypt sensitive data
    func retrieve<T: Codable>(
        _ type: T.Type,
        for key: String,
        itemType: KeychainItemType = .generic(account: ""),
        promptMessage: String? = nil
    ) throws -> T? {

        var query = buildBaseQuery(for: itemType, key: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup
        }

        // Set biometric prompt if provided
        if let promptMessage = promptMessage {
            query[kSecUseOperationPrompt as String] = promptMessage
        }

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                return nil
            }
            SecureLogger.shared.error("Failed to retrieve keychain item \(key): \(status)")
            throw KeychainError.retrieveFailed(status: status)
        }

        guard let encryptedData = result as? Data else {
            throw KeychainError.invalidData
        }

        // Decrypt data
        let decryptedData: Data
        do {
            decryptedData = try decryptData(encryptedData, for: key)
        } catch {
            SecureLogger.shared.error("Failed to decrypt data for key \(key): \(error)")
            throw KeychainError.decryptionFailed
        }

        // Decode data
        do {
            let decodedData = try JSONDecoder().decode(type, from: decryptedData)
            return decodedData
        } catch {
            SecureLogger.shared.error("Failed to decode data for key \(key): \(error)")
            throw KeychainError.decodingFailed
        }
    }

    /// Store string data (legacy support)
    func storeString(
        _ string: String,
        for key: String,
        accessControl: AccessControl = .whenUnlockedThisDeviceOnly
    ) throws {
        try store(string, for: key, accessControl: accessControl)
    }

    /// Retrieve string data (legacy support)
    func retrieveString(for key: String, promptMessage: String? = nil) throws -> String? {
        return try retrieve(String.self, for: key, promptMessage: promptMessage)
    }

    /// Delete keychain item
    func delete(for key: String, itemType: KeychainItemType = .generic(account: "")) throws {
        let query = buildBaseQuery(for: itemType, key: key)

        let status = SecItemDelete(query as CFDictionary)

        if status != errSecSuccess && status != errSecItemNotFound {
            SecureLogger.shared.error("Failed to delete keychain item \(key): \(status)")
            throw KeychainError.deleteFailed(status: status)
        }

        SecureLogger.shared.info("Successfully deleted keychain item: \(key)")
    }

    /// Check if keychain item exists
    func exists(for key: String, itemType: KeychainItemType = .generic(account: "")) -> Bool {
        var query = buildBaseQuery(for: itemType, key: key)
        query[kSecReturnData as String] = false
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        let status = SecItemCopyMatching(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    /// Clear all keychain items for this app
    func clearAll() throws {
        let itemTypes: [KeychainItemType] = [
            .generic(account: ""),
            .internetPassword(server: "", account: ""),
            .certificate(label: ""),
            .key(applicationTag: "")
        ]

        for itemType in itemTypes {
            let query: [String: Any] = [
                kSecClass as String: itemType.secClass,
                kSecAttrService as String: serviceIdentifier
            ]

            let status = SecItemDelete(query as CFDictionary)
            if status != errSecSuccess && status != errSecItemNotFound {
                SecureLogger.shared.warning("Failed to clear keychain items of type \(itemType): \(status)")
            }
        }

        SecureLogger.shared.info("Keychain cleared for app")
    }

    // MARK: - Private Methods

    private func buildBaseQuery(for itemType: KeychainItemType, key: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: itemType.secClass,
            kSecAttrService as String: serviceIdentifier
        ]

        switch itemType {
        case .generic(let account):
            query[kSecAttrAccount as String] = account.isEmpty ? key : account
        case .internetPassword(let server, let account):
            query[kSecAttrServer as String] = server
            query[kSecAttrAccount as String] = account.isEmpty ? key : account
        case .certificate(let label):
            query[kSecAttrLabel as String] = label.isEmpty ? key : label
        case .key(let applicationTag):
            query[kSecAttrApplicationTag as String] = applicationTag.isEmpty ? key.data(using: .utf8)! : applicationTag.data(using: .utf8)!
        }

        return query
    }

    // MARK: - Encryption Methods

    private func encryptData(_ data: Data, for key: String) throws -> Data {
        // Generate a unique encryption key based on the keychain key
        let keyData = key.data(using: .utf8)!
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: keyData))

        // Encrypt using AES-GCM
        let sealedBox = try AES.GCM.seal(data, using: symmetricKey)

        guard let encryptedData = sealedBox.combined else {
            throw KeychainError.encryptionFailed
        }

        return encryptedData
    }

    private func decryptData(_ encryptedData: Data, for key: String) throws -> Data {
        // Regenerate the same encryption key
        let keyData = key.data(using: .utf8)!
        let symmetricKey = SymmetricKey(data: SHA256.hash(data: keyData))

        // Decrypt using AES-GCM
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: symmetricKey)

        return decryptedData
    }

    // MARK: - Device Security Checks

    /// Check if device has passcode set
    func isDeviceSecure() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "device_security_check",
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            kSecValueData as String: "test".data(using: .utf8)!
        ]

        // Try to add an item that requires passcode
        let status = SecItemAdd(query as CFDictionary, nil)

        // Clean up test item
        SecItemDelete(query as CFDictionary)

        return status == errSecSuccess
    }

    /// Check if biometry is available and configured
    func isBiometryAvailable() -> Bool {
        var error: Unmanaged<CFError>?
        let accessControl = SecAccessControlCreateWithFlags(
            kCFAllocatorDefault,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            .biometryAny,
            &error
        )

        return accessControl != nil && error == nil
    }
}

// MARK: - KeychainError

enum KeychainError: Error, LocalizedError {
    case encodingFailed
    case decodingFailed
    case encryptionFailed
    case decryptionFailed
    case accessControlFailed
    case storeFailed(status: OSStatus)
    case updateFailed(status: OSStatus)
    case retrieveFailed(status: OSStatus)
    case deleteFailed(status: OSStatus)
    case invalidData

    var errorDescription: String? {
        switch self {
        case .encodingFailed:
            return "Failed to encode data for keychain storage"
        case .decodingFailed:
            return "Failed to decode data from keychain"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .accessControlFailed:
            return "Failed to create access control"
        case .storeFailed(let status):
            return "Failed to store item in keychain (status: \(status))"
        case .updateFailed(let status):
            return "Failed to update item in keychain (status: \(status))"
        case .retrieveFailed(let status):
            return "Failed to retrieve item from keychain (status: \(status))"
        case .deleteFailed(let status):
            return "Failed to delete item from keychain (status: \(status))"
        case .invalidData:
            return "Invalid keychain data format"
        }
    }
}

// MARK: - Secure Data Types

/// Wrapper for sensitive string data that clears itself from memory
final class SecureString {
    private var _value: String?

    init(_ value: String) {
        self._value = value
    }

    var value: String? {
        return _value
    }

    func clear() {
        _value = nil
    }

    deinit {
        clear()
    }
}

/// Wrapper for sensitive data that clears itself from memory
final class SecureData {
    private var _data: Data?

    init(_ data: Data) {
        self._data = data
    }

    var data: Data? {
        return _data
    }

    func clear() {
        if var data = _data {
            // Overwrite with random data before clearing
            for i in 0..<data.count {
                data[i] = UInt8.random(in: 0...255)
            }
            _data = nil
        }
    }

    deinit {
        clear()
    }
}