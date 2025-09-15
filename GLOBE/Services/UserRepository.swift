//======================================================================
// MARK: - UserRepository.swift
// Purpose: User data repository implementation
// Path: GLOBE/Core/Repositories/UserRepository.swift
//======================================================================

import Foundation
import Supabase

@MainActor
class UserRepository: UserRepositoryProtocol {
    private let supabaseClient: SupabaseClient
    private let cacheRepository: CacheRepositoryProtocol

    init(supabaseClient: SupabaseClient, cacheRepository: CacheRepositoryProtocol) {
        self.supabaseClient = supabaseClient
        self.cacheRepository = cacheRepository
    }

    // MARK: - User Management

    func getUser(by id: String) async throws -> AppUser? {
        do {
            guard let uuid = UUID(uuidString: id) else {
                SecureLogger.shared.error("Invalid user id format: \(id)")
                return nil
            }
            let user = try await supabaseClient.auth.admin.getUserById(uuid)

            return AppUser(
                id: user.id.uuidString,
                email: user.email,
                username: user.userMetadata["username"]?.stringValue,
                createdAt: user.createdAt.ISO8601Format()
            )
        } catch {
            SecureLogger.shared.error("Failed to get user by id: \(id) - \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }

    func getCurrentUser() async throws -> AppUser? {
        do {
            let session = try await supabaseClient.auth.session
            let user = session.user

            return AppUser(
                id: user.id.uuidString,
                email: user.email,
                username: user.userMetadata["username"]?.stringValue,
                createdAt: user.createdAt.ISO8601Format()
            )
        } catch {
            SecureLogger.shared.info("No current user session found")
            return nil
        }
    }

    func updateUserProfile(_ user: AppUser) async throws -> Bool {
        do {
            let updates = [
                "email": user.email,
                "data": [
                    "username": user.username ?? ""
                ]
            ] as [String : Any]

            _ = try await supabaseClient.auth.update(user: UserAttributes(
                email: user.email,
                data: ["username": AnyJSON.string(user.username ?? "")]
            ))

            SecureLogger.shared.info("User profile updated successfully")
            return true
        } catch {
            SecureLogger.shared.error("Failed to update user profile: \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }

    func deleteUser(_ userId: String) async throws -> Bool {
        do {
            // Note: User deletion typically requires admin privileges
            // This is a placeholder implementation
            SecureLogger.shared.securityEvent("User deletion requested", details: ["userId": userId])
            return false // Not implemented for security reasons
        } catch {
            SecureLogger.shared.error("Failed to delete user: \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }

    // MARK: - User Profile Management

    func getUserProfile(by id: String) async throws -> UserProfile? {
        // First check cache
        if let cachedProfile = try? await cacheRepository.getCachedUserProfile(for: id) {
            return cachedProfile
        }

        do {
            let response = try await supabaseClient
                .from("profiles")
                .select()
                .eq("id", value: id)
                .single()
                .execute()

            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601

            let profile = try decoder.decode(UserProfile.self, from: response.data)

            // Cache the profile
            try await cacheRepository.cacheUserProfile(profile, for: id)

            return profile
        } catch {
            SecureLogger.shared.error("Failed to get user profile by id: \(id) - \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }

    func updateUserProfile(_ profile: UserProfile) async throws -> Bool {
        do {
            let iso = ISO8601DateFormatter()
            let updates: [String: AnyJSON] = [
                "username": .string(profile.username),
                "display_name": profile.displayName.map { .string($0) } ?? .null,
                "bio": profile.bio.map { .string($0) } ?? .null,
                "avatar_url": profile.avatarUrl.map { .string($0) } ?? .null,
                "updated_at": .string(iso.string(from: Date()))
            ]

            _ = try await supabaseClient
                .from("profiles")
                .update(updates)
                .eq("id", value: profile.id)
                .execute()

            // Update cache
            try await cacheRepository.cacheUserProfile(profile, for: profile.id)

            SecureLogger.shared.info("User profile updated successfully in database")
            return true
        } catch {
            SecureLogger.shared.error("Failed to update user profile in database: \(error.localizedDescription)")
            throw AppError.from(error)
        }
    }
}

// MARK: - Repository Extension for Service Container

extension UserRepository {
    static func create() -> UserRepository {
        let cacheRepository = ServiceContainer.shared.resolve(CacheRepositoryProtocol.self) ?? CacheRepository()
        return UserRepository(supabaseClient: SupabaseManager.shared.syncClient, cacheRepository: cacheRepository)
    }
}
