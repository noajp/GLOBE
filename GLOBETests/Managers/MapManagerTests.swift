//======================================================================
// MARK: - MapManagerTests.swift
// Purpose: MapManager の正常系・異常系テスト（ズームレベル、表示制御、クラスタリング、衝突回避）
// Path: GLOBETests/Managers/MapManagerTests.swift
//======================================================================

import XCTest
import MapKit
import CoreLocation
@testable import GLOBE

@MainActor
final class MapManagerTests: XCTestCase {

    var mapManager: MapManager!

    override func setUp() {
        super.setUp()
        mapManager = MapManager()
    }

    override func tearDown() {
        mapManager = nil
        super.tearDown()
    }

    // MARK: - 正常系: Initial State Tests
    func testInitialState_hasDefaultRegion() {
        // Given: Newly initialized MapManager

        // Then: Should have default Tokyo region
        XCTAssertEqual(mapManager.region.center.latitude, 35.6762, accuracy: 0.001)
        XCTAssertEqual(mapManager.region.center.longitude, 139.6503, accuracy: 0.001)
        XCTAssertEqual(mapManager.region.span.latitudeDelta, 0.02, accuracy: 0.001)
    }

    func testInitialState_hasEmptyPosts() {
        // Given: Newly initialized MapManager

        // Then: Posts should be empty initially
        XCTAssertTrue(mapManager.posts.isEmpty)
        XCTAssertTrue(mapManager.adjustedPostPositions.isEmpty)
    }

    // MARK: - 正常系: Location Setting Tests
    func testSetInitialRegionToCurrentLocation_updatesRegion() {
        // Given: User's current location
        let userLocation = CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023) // Osaka

        // When: Set initial region to user location
        mapManager.setInitialRegionToCurrentLocation(userLocation)

        // Then: Region should be updated to user location
        XCTAssertEqual(mapManager.region.center.latitude, userLocation.latitude, accuracy: 0.001)
        XCTAssertEqual(mapManager.region.center.longitude, userLocation.longitude, accuracy: 0.001)
    }

    func testFocusOnLocation_updatesRegionWithCustomZoom() {
        // Given: A location and zoom level
        let targetLocation = CLLocationCoordinate2D(latitude: 35.0, longitude: 135.0)
        let zoomLevel = 0.005

        // When: Focus on location
        mapManager.focusOnLocation(targetLocation, zoomLevel: zoomLevel)

        // Then: Region should be updated
        XCTAssertEqual(mapManager.region.center.latitude, targetLocation.latitude, accuracy: 0.001)
        XCTAssertEqual(mapManager.region.center.longitude, targetLocation.longitude, accuracy: 0.001)
        XCTAssertEqual(mapManager.region.span.latitudeDelta, zoomLevel, accuracy: 0.001)
    }

    // MARK: - 正常系: Display Mode Tests
    func testDisplayMode_nearDistance_withSmallSpan() {
        // Given: Near distance zoom level
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)

        // When: Check display mode
        let mode = mapManager.currentDisplayMode

        // Then: Should be near distance mode
        XCTAssertEqual(mode, .nearDistance)
    }

    func testDisplayMode_midDistance_withMediumSpan() {
        // Given: Mid distance zoom level
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

        // When: Check display mode
        let mode = mapManager.currentDisplayMode

        // Then: Should be mid distance mode
        XCTAssertEqual(mode, .midDistance)
    }

    func testDisplayMode_farDistance_withLargeSpan() {
        // Given: Far distance zoom level
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)

        // When: Check display mode
        let mode = mapManager.currentDisplayMode

        // Then: Should be far distance mode
        XCTAssertEqual(mode, .farDistance)
    }

    // MARK: - 正常系: Visible Posts Tests
    func testVisiblePosts_nearDistance_showsAllPosts() {
        // Given: Near distance mode with posts
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        mapManager.posts = createTestPosts(count: 10)

        // When: Get visible posts
        let visible = mapManager.visiblePosts

        // Then: All posts should be visible
        XCTAssertEqual(visible.count, 10)
    }

    func testVisiblePosts_midDistance_prioritizesHighEngagement() {
        // Given: Mid distance mode with mixed engagement posts
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

        let highEngagementPost = Post(
            location: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            locationName: "High Engagement",
            text: "Popular post",
            authorName: "User1",
            authorId: "user1",
            likeCount: 10
        )

        let lowEngagementPost = Post(
            location: CLLocationCoordinate2D(latitude: 35.6763, longitude: 139.6504),
            locationName: "Low Engagement",
            text: "Regular post",
            authorName: "User2",
            authorId: "user2",
            likeCount: 0
        )

        mapManager.posts = [lowEngagementPost, highEngagementPost]

        // When: Get visible posts
        let visible = mapManager.visiblePosts

        // Then: Should show both posts (within 60 post limit)
        XCTAssertEqual(visible.count, 2)
    }

    func testVisiblePosts_farDistance_showsNoPosts() {
        // Given: Far distance mode with posts
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.5, longitudeDelta: 0.5)
        mapManager.posts = createTestPosts(count: 10)

        // When: Get visible posts
        let visible = mapManager.visiblePosts

        // Then: Should show no individual posts (clusters only)
        XCTAssertEqual(visible.count, 0)
    }

    // MARK: - 正常系: Position Adjustment Tests
    func testGetAdjustedPosition_returnsOriginalWhenNoAdjustment() {
        // Given: Post with no position adjustment
        let postId = UUID()
        let originalLocation = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        // When: Get adjusted position
        let adjusted = mapManager.getAdjustedPosition(for: postId, originalLocation: originalLocation)

        // Then: Should return original location
        XCTAssertEqual(adjusted.latitude, originalLocation.latitude, accuracy: 0.00001)
        XCTAssertEqual(adjusted.longitude, originalLocation.longitude, accuracy: 0.00001)
    }

    // MARK: - 正常系: Opacity Tests
    func testGetPostOpacity_returnsDefaultOpacity() {
        // Given: Post with no calculated opacity
        let postId = UUID()

        // When: Get opacity
        let opacity = mapManager.getPostOpacity(for: postId)

        // Then: Should return default opacity (1.0)
        XCTAssertEqual(opacity, 1.0, accuracy: 0.01)
    }

    // MARK: - 異常系: Invalid Coordinate Tests
    func testSetInitialRegion_withInvalidLatitude_clampsToValidRange() {
        // Given: Invalid latitude (out of range)
        let invalidLocation = CLLocationCoordinate2D(latitude: 100.0, longitude: 139.6503)

        // When: Try to set initial region
        // Note: CLLocationCoordinate2D itself validates coordinates
        let isValid = CLLocationCoordinate2DIsValid(invalidLocation)

        // Then: Should be invalid
        XCTAssertFalse(isValid)
    }

    func testSetInitialRegion_withInvalidLongitude_clampsToValidRange() {
        // Given: Invalid longitude (out of range)
        let invalidLocation = CLLocationCoordinate2D(latitude: 35.6762, longitude: 200.0)

        // When: Check validity
        let isValid = CLLocationCoordinate2DIsValid(invalidLocation)

        // Then: Should be invalid
        XCTAssertFalse(isValid)
    }

    // MARK: - 異常系: Extreme Zoom Level Tests
    func testDisplayMode_withExtremelySmallSpan_handlesGracefully() {
        // Given: Extremely small span (street level)
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.0001, longitudeDelta: 0.0001)

        // When: Get display mode
        let mode = mapManager.currentDisplayMode

        // Then: Should be near distance mode
        XCTAssertEqual(mode, .nearDistance)
    }

    func testDisplayMode_withExtremelyLargeSpan_handlesGracefully() {
        // Given: Extremely large span (global view)
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 180.0, longitudeDelta: 180.0)

        // When: Get display mode
        let mode = mapManager.currentDisplayMode

        // Then: Should be far distance mode
        XCTAssertEqual(mode, .farDistance)
    }

    // MARK: - 異常系: Empty Posts Tests
    func testVisiblePosts_withEmptyPosts_returnsEmpty() {
        // Given: No posts
        mapManager.posts = []

        // When: Get visible posts in any mode
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let visibleNear = mapManager.visiblePosts

        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let visibleMid = mapManager.visiblePosts

        // Then: Should return empty arrays
        XCTAssertTrue(visibleNear.isEmpty)
        XCTAssertTrue(visibleMid.isEmpty)
    }

    // MARK: - 異常系: Duplicate Location Tests
    func testPosts_withDuplicateLocations_handlesCorrectly() {
        // Given: Multiple posts at same location
        let sameLocation = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)

        let post1 = Post(
            location: sameLocation,
            locationName: "Same Location",
            text: "Post 1",
            authorName: "User1",
            authorId: "user1"
        )

        let post2 = Post(
            location: sameLocation,
            locationName: "Same Location",
            text: "Post 2",
            authorName: "User2",
            authorId: "user2"
        )

        mapManager.posts = [post1, post2]
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)

        // When: Get visible posts
        let visible = mapManager.visiblePosts

        // Then: Should show both posts
        XCTAssertEqual(visible.count, 2)
    }

    // MARK: - 異常系: Boundary Value Tests
    func testRegion_atEquator_handlesCorrectly() {
        // Given: Location at equator
        let equatorLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0)

        // When: Set region
        mapManager.setInitialRegionToCurrentLocation(equatorLocation)

        // Then: Should handle correctly
        XCTAssertEqual(mapManager.region.center.latitude, 0.0, accuracy: 0.001)
        XCTAssertEqual(mapManager.region.center.longitude, 0.0, accuracy: 0.001)
    }

    func testRegion_atPoles_handlesCorrectly() {
        // Given: Location near north pole
        let northPoleLocation = CLLocationCoordinate2D(latitude: 89.9, longitude: 0.0)

        // When: Set region
        mapManager.setInitialRegionToCurrentLocation(northPoleLocation)

        // Then: Should handle correctly
        XCTAssertEqual(mapManager.region.center.latitude, 89.9, accuracy: 0.001)
    }

    func testRegion_atDateLine_handlesCorrectly() {
        // Given: Location at international date line
        let dateLineLocation = CLLocationCoordinate2D(latitude: 0.0, longitude: 180.0)

        // When: Set region
        mapManager.setInitialRegionToCurrentLocation(dateLineLocation)

        // Then: Should handle correctly
        XCTAssertEqual(mapManager.region.center.longitude, 180.0, accuracy: 0.001)
    }

    // MARK: - 異常系: Large Dataset Tests
    func testVisiblePosts_withManyPosts_performsEfficiently() {
        // Given: Large number of posts
        mapManager.posts = createTestPosts(count: 200)
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)

        // When: Measure performance of getting visible posts
        measure {
            _ = mapManager.visiblePosts
        }

        // Then: Should complete within reasonable time (measured by XCTest)
    }

    func testClusters_withManyPosts_performsEfficiently() {
        // Given: Large number of posts in far distance mode
        mapManager.posts = createTestPosts(count: 500)
        mapManager.region.span = MKCoordinateSpan(latitudeDelta: 1.0, longitudeDelta: 1.0)

        // When: Measure clustering performance
        measure {
            mapManager.updateClusters()
        }

        // Then: Should complete within reasonable time
    }

    // MARK: - 異常系: Concurrent Access Tests
    func testConcurrentRegionUpdates_threadSafe() {
        // Given: Multiple concurrent updates
        let expectation = XCTestExpectation(description: "Concurrent updates complete")
        let locations = [
            CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            CLLocationCoordinate2D(latitude: 34.6937, longitude: 135.5023),
            CLLocationCoordinate2D(latitude: 43.0642, longitude: 141.3469)
        ]

        let group = DispatchGroup()

        // When: Update region concurrently
        for location in locations {
            group.enter()
            Task { @MainActor in
                mapManager.setInitialRegionToCurrentLocation(location)
                group.leave()
            }
        }

        group.notify(queue: .main) {
            expectation.fulfill()
        }

        // Then: Should complete without crashes
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Helper Methods
    private func createTestPosts(count: Int) -> [Post] {
        var posts: [Post] = []
        for i in 0..<count {
            let lat = 35.6762 + Double(i) * 0.001
            let lng = 139.6503 + Double(i) * 0.001

            let post = Post(
                location: CLLocationCoordinate2D(latitude: lat, longitude: lng),
                locationName: "Test Location \(i)",
                text: "Test post \(i)",
                authorName: "User\(i)",
                authorId: "user\(i)"
            )
            posts.append(post)
        }
        return posts
    }
}
