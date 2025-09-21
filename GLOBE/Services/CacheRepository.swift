//======================================================================
// MARK: - CacheRepository.swift
// Purpose: Cache data repository implementation
// Path: GLOBE/Core/Repositories/CacheRepository.swift
//======================================================================

import Foundation
import UIKit

@MainActor
class CacheRepository: CacheRepositoryProtocol {
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let userProfileCacheDirectory: URL
    private let imageCacheDirectory: URL

    // In-memory cache for frequently accessed data
    private var memoryImageCache: NSCache<NSString, NSData>
    private var memoryProfileCache: [String: UserProfile] = [:]

    init() {
        // Setup cache directories
        let cachesDirectory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
        self.cacheDirectory = cachesDirectory.appendingPathComponent("GLOBECache")
        self.imageCacheDirectory = cacheDirectory.appendingPathComponent("Images")
        self.userProfileCacheDirectory = cacheDirectory.appendingPathComponent("UserProfiles")

        // Setup in-memory caches
        self.memoryImageCache = NSCache<NSString, NSData>()
        self.memoryImageCache.countLimit = 100 // Limit to 100 images in memory
        self.memoryImageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB limit

        // UserProfile cache is a simple dictionary since NSCache requires class types
        self.memoryProfileCache = [:]

        // Create cache directories if they don't exist
        createCacheDirectoriesIfNeeded()
    }

    // MARK: - Setup

    private func createCacheDirectoriesIfNeeded() {
        let directories = [cacheDirectory, imageCacheDirectory, userProfileCacheDirectory]

        for directory in directories {
            if !fileManager.fileExists(atPath: directory.path) {
                do {
                    try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
                    SecureLogger.shared.info("Created cache directory: \(directory.lastPathComponent)")
                } catch {
                    SecureLogger.shared.error("Failed to create cache directory: \(error.localizedDescription)")
                }
            }
        }
    }

    // MARK: - Image Cache

    func cacheImage(data: Data, for key: String) async throws {
        let cacheKey = NSString(string: key)

        // Store in memory cache
        memoryImageCache.setObject(NSData(data: data), forKey: cacheKey)

        // Store in disk cache
        let fileURL = imageCacheDirectory.appendingPathComponent("\(key.hash).cache")

        do {
            try data.write(to: fileURL)
            SecureLogger.shared.info("Image cached to disk - key: \(key)")
        } catch {
            SecureLogger.shared.error("Failed to cache image to disk: \(error.localizedDescription)")
            throw AppError.storageError("Failed to cache image")
        }
    }

    func getCachedImage(for key: String) async throws -> Data? {
        let cacheKey = NSString(string: key)

        // First check memory cache
        if let memoryData = memoryImageCache.object(forKey: cacheKey) {
            return Data(referencing: memoryData)
        }

        // Then check disk cache
        let fileURL = imageCacheDirectory.appendingPathComponent("\(key.hash).cache")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)

            // Store back in memory cache for future access
            memoryImageCache.setObject(NSData(data: data), forKey: cacheKey)

            return data
        } catch {
            SecureLogger.shared.error("Failed to read cached image: \(error.localizedDescription)")
            throw AppError.storageError("Failed to read cached image")
        }
    }

    func removeCachedImage(for key: String) async throws {
        let cacheKey = NSString(string: key)

        // Remove from memory cache
        memoryImageCache.removeObject(forKey: cacheKey)

        // Remove from disk cache
        let fileURL = imageCacheDirectory.appendingPathComponent("\(key.hash).cache")

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                SecureLogger.shared.info("Removed cached image - key: \(key)")
            } catch {
                SecureLogger.shared.error("Failed to remove cached image: \(error.localizedDescription)")
                throw AppError.storageError("Failed to remove cached image")
            }
        }
    }

    // MARK: - User Profile Cache

    func cacheUserProfile(_ profile: UserProfile, for userId: String) async throws {
        let _ = NSString(string: userId)

        // Store in memory cache
        memoryProfileCache[userId] = profile

        // Store in disk cache
        let fileURL = userProfileCacheDirectory.appendingPathComponent("\(userId).json")

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(profile)
            try data.write(to: fileURL)
            SecureLogger.shared.info("User profile cached - userId: \(userId)")
        } catch {
            SecureLogger.shared.error("Failed to cache user profile: \(error.localizedDescription)")
            throw AppError.storageError("Failed to cache user profile")
        }
    }

    func getCachedUserProfile(for userId: String) async throws -> UserProfile? {
        let _ = NSString(string: userId)

        // First check memory cache
        if let memoryProfile = memoryProfileCache[userId] {
            return memoryProfile
        }

        // Then check disk cache
        let fileURL = userProfileCacheDirectory.appendingPathComponent("\(userId).json")

        guard fileManager.fileExists(atPath: fileURL.path) else {
            return nil
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let profile = try decoder.decode(UserProfile.self, from: data)

            // Store back in memory cache
            memoryProfileCache[userId] = profile

            return profile
        } catch {
            SecureLogger.shared.error("Failed to read cached user profile: \(error.localizedDescription)")
            throw AppError.storageError("Failed to read cached user profile")
        }
    }

    func removeCachedUserProfile(for userId: String) async throws {
        let _ = NSString(string: userId)

        // Remove from memory cache
        memoryProfileCache.removeValue(forKey: userId)

        // Remove from disk cache
        let fileURL = userProfileCacheDirectory.appendingPathComponent("\(userId).json")

        if fileManager.fileExists(atPath: fileURL.path) {
            do {
                try fileManager.removeItem(at: fileURL)
                SecureLogger.shared.info("Removed cached user profile - userId: \(userId)")
            } catch {
                SecureLogger.shared.error("Failed to remove cached user profile: \(error.localizedDescription)")
                throw AppError.storageError("Failed to remove cached user profile")
            }
        }
    }

    // MARK: - Cache Management

    func clearAllCache() async throws {
        // Clear memory caches
        memoryImageCache.removeAllObjects()
        memoryProfileCache.removeAll()

        // Clear disk caches
        let directories = [imageCacheDirectory, userProfileCacheDirectory]

        for directory in directories {
            if fileManager.fileExists(atPath: directory.path) {
                do {
                    let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)
                    for file in files {
                        try fileManager.removeItem(at: file)
                    }
                    SecureLogger.shared.info("Cleared cache directory: \(directory.lastPathComponent)")
                } catch {
                    SecureLogger.shared.error("Failed to clear cache directory: \(error.localizedDescription)")
                    throw AppError.storageError("Failed to clear cache")
                }
            }
        }
    }

    func getCacheSize() async throws -> Int64 {
        var totalSize: Int64 = 0

        let directories = [imageCacheDirectory, userProfileCacheDirectory]

        for directory in directories {
            if fileManager.fileExists(atPath: directory.path) {
                do {
                    let files = try fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: [.fileSizeKey])

                    for file in files {
                        let attributes = try file.resourceValues(forKeys: [.fileSizeKey])
                        totalSize += Int64(attributes.fileSize ?? 0)
                    }
                } catch {
                    SecureLogger.shared.error("Failed to calculate cache size: \(error.localizedDescription)")
                    throw AppError.storageError("Failed to calculate cache size")
                }
            }
        }

        return totalSize
    }
}

// MARK: - Repository Extension for Service Container

extension CacheRepository {
    static func create() -> CacheRepository {
        return CacheRepository()
    }
}