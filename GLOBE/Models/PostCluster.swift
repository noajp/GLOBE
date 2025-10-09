//======================================================================
// MARK: - PostCluster.swift
// Purpose: Represents a cluster of posts for far-distance display
// Path: GLOBE/Models/PostCluster.swift
//======================================================================

import Foundation
import CoreLocation

struct PostCluster: Identifiable {
    let id = UUID()
    let location: CLLocationCoordinate2D
    let posts: [Post]

    var postCount: Int {
        return posts.count
    }

    // Center point of all posts in the cluster
    init(posts: [Post]) {
        self.posts = posts

        // Calculate centroid
        let avgLat = posts.map { $0.location.latitude }.reduce(0, +) / Double(posts.count)
        let avgLng = posts.map { $0.location.longitude }.reduce(0, +) / Double(posts.count)

        self.location = CLLocationCoordinate2D(latitude: avgLat, longitude: avgLng)
    }
}
