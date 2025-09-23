//======================================================================
// MARK: - ProfileImageCacheManager.swift
// Purpose: Cache and preload profile images for better performance
// Path: GLOBE/Core/Managers/ProfileImageCacheManager.swift
//======================================================================

import SwiftUI
import Combine
import Supabase

final class ProfileImageCacheManager: ObservableObject {
    // MARK: - Singleton
    static let shared = ProfileImageCacheManager()
    
    // MARK: - Properties
    @Published private(set) var cachedImages: [String: UIImage] = [:]
    private var imageLoadingTasks: [String: Task<UIImage?, Never>] = [:]
    private let imageCache = NSCache<NSString, UIImage>()
    
    // MARK: - Initialization
    private init() {
        // Configure cache
        imageCache.countLimit = 50 // Maximum 50 images
        imageCache.totalCostLimit = 50 * 1024 * 1024 // Maximum 50MB
    }
    
    // MARK: - Public Methods
    
    /// Preload current user's profile image on app launch
    func preloadCurrentUserProfileImage() async {
        guard let userId = AuthManager.shared.currentUser?.id else { return }
        
        do {
            // Fetch user profile to get avatar URL
            let profileData = try await SupabaseManager.shared.client
                .from("profiles")
                .select("avatar_url")
                .eq("id", value: userId)
                .execute()
            
            if let profiles = try? JSONDecoder().decode([[String: String?]].self, from: profileData.data),
               let profile = profiles.first,
               let avatarUrlString = profile["avatar_url"],
               let avatarUrl = avatarUrlString,
               !avatarUrl.isEmpty,
               let url = URL(string: avatarUrl) {
                
                // Preload the image
                _ = await loadImage(from: url, cacheKey: userId)
                print("✅ ProfileImageCache: Preloaded current user profile image")
            }
        } catch {
            print("❌ ProfileImageCache: Failed to preload profile image: \(error)")
        }
    }
    
    /// Get cached image or load it
    func getImage(for urlString: String?, userId: String) async -> UIImage? {
        guard let urlString = urlString,
              !urlString.isEmpty,
              let url = URL(string: urlString) else { return nil }
        
        // Check memory cache first
        if let cachedImage = imageCache.object(forKey: userId as NSString) {
            return cachedImage
        }
        
        // Load image
        return await loadImage(from: url, cacheKey: userId)
    }
    
    /// Get cached image synchronously (for immediate display)
    func getCachedImage(for userId: String) -> UIImage? {
        return imageCache.object(forKey: userId as NSString)
    }
    
    // MARK: - Private Methods
    
    private func loadImage(from url: URL, cacheKey: String) async -> UIImage? {
        // Check if already loading
        if let existingTask = imageLoadingTasks[cacheKey] {
            return await existingTask.value
        }
        
        // Create new loading task
        let task = Task<UIImage?, Never> {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    // Cache the image
                    await MainActor.run {
                        self.imageCache.setObject(image, forKey: cacheKey as NSString, cost: data.count)
                        self.cachedImages[cacheKey] = image
                    }
                    return image
                }
            } catch {
                print("❌ ProfileImageCache: Failed to load image: \(error)")
            }
            return nil
        }
        
        imageLoadingTasks[cacheKey] = task
        let image = await task.value
        imageLoadingTasks.removeValue(forKey: cacheKey)
        
        return image
    }
    
    /// Clear cache to free memory
    func clearCache() {
        imageCache.removeAllObjects()
        cachedImages.removeAll()
        
        // Cancel all loading tasks
        for task in imageLoadingTasks.values {
            task.cancel()
        }
        imageLoadingTasks.removeAll()
    }
}