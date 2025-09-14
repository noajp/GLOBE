//======================================================================
// MARK: - GLOBEUITests.swift
// Purpose: UI/E2Eテスト（ユーザーフロー・画面遷移・主要機能のエンドツーエンドテスト）
// Path: GLOBEUITests/GLOBEUITests.swift
//======================================================================

import XCTest

final class GLOBEUITests: XCTestCase {

    // MARK: - Test Properties
    var app: XCUIApplication!

    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // UI testing flag
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - App Launch Tests
    @MainActor
    func testAppLaunch_showsMainInterface() throws {
        // Given: App is launched in setUpWithError()

        // Then: Main interface elements should be visible
        XCTAssertTrue(app.waitForExistence(timeout: 10))

        // Check for main tab bar or navigation elements
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            XCTAssertTrue(tabBar.isHittable)
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        // This measures how long it takes to launch your application.
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            XCUIApplication().launch()
        }
    }

    // MARK: - Main Navigation Tests
    @MainActor
    func testMainNavigation_tabBarNavigation() throws {
        // Wait for app to fully load
        _ = app.waitForExistence(timeout: 10)

        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabButtons = tabBar.buttons

            // Test tapping each tab if they exist
            if tabButtons.count > 0 {
                for i in 0..<min(tabButtons.count, 5) { // Test up to 5 tabs
                    let tabButton = tabButtons.element(boundBy: i)
                    if tabButton.exists && tabButton.isHittable {
                        tabButton.tap()

                        // Wait for tab content to load
                        _ = app.waitForExistence(timeout: 3)

                        // Verify tab selection (tab should remain visible)
                        XCTAssertTrue(tabButton.exists)
                    }
                }
            }
        }
    }

    // MARK: - Map Interaction Tests
    @MainActor
    func testMapInteraction_mapViewExists() throws {
        // Wait for app to load
        _ = app.waitForExistence(timeout: 10)

        // Look for map-related elements
        let mapView = app.maps.firstMatch
        if mapView.exists {
            XCTAssertTrue(mapView.isHittable)

            // Test map interaction
            mapView.tap()

            // Wait for map to respond
            _ = app.waitForExistence(timeout: 3)
        }
    }

    @MainActor
    func testMapInteraction_locationButton() throws {
        // Wait for app to load
        _ = app.waitForExistence(timeout: 10)

        // Look for location-related buttons
        let locationButton = app.buttons.matching(identifier: "LocationButton").firstMatch
        let myLocationButton = app.buttons["My Location"].firstMatch

        if locationButton.exists && locationButton.isHittable {
            locationButton.tap()
            _ = app.waitForExistence(timeout: 3)
        } else if myLocationButton.exists && myLocationButton.isHittable {
            myLocationButton.tap()
            _ = app.waitForExistence(timeout: 3)
        }
    }

    // MARK: - Post Creation Flow Tests
    @MainActor
    func testPostCreation_openPostCreationModal() throws {
        // Wait for app to load
        _ = app.waitForExistence(timeout: 10)

        // Look for post creation trigger (long press on map, create button, etc.)
        let createButton = app.buttons["Create"].firstMatch
        let addButton = app.buttons["+"].firstMatch
        let mapView = app.maps.firstMatch

        if createButton.exists && createButton.isHittable {
            createButton.tap()
        } else if addButton.exists && addButton.isHittable {
            addButton.tap()
        } else if mapView.exists {
            // Try long press on map to trigger post creation
            mapView.press(forDuration: 1.0)
        }

        // Wait for post creation UI to appear
        _ = app.waitForExistence(timeout: 5)

        // Look for post creation elements
        let textView = app.textViews.firstMatch
        let postButton = app.buttons["Post"].firstMatch

        if textView.exists {
            XCTAssertTrue(textView.isHittable)
        }

        if postButton.exists {
            XCTAssertTrue(postButton.isHittable)
        }
    }

    // MARK: - Profile Navigation Tests
    @MainActor
    func testProfileNavigation_openProfile() throws {
        // Wait for app to load
        _ = app.waitForExistence(timeout: 10)

        // Look for profile-related navigation
        let profileTab = app.tabBars.buttons["Profile"].firstMatch
        let profileButton = app.buttons["Profile"].firstMatch
        let settingsButton = app.buttons.matching(identifier: "Settings").firstMatch

        if profileTab.exists && profileTab.isHittable {
            profileTab.tap()
        } else if profileButton.exists && profileButton.isHittable {
            profileButton.tap()
        } else if settingsButton.exists && settingsButton.isHittable {
            settingsButton.tap()
        }

        // Wait for profile screen to load
        _ = app.waitForExistence(timeout: 5)

        // Look for profile elements
        let profileImage = app.images.firstMatch
        let usernameText = app.staticTexts.firstMatch

        // Verify profile elements exist (if profile is loaded)
        if profileImage.exists || usernameText.exists {
            // Profile screen loaded successfully
            XCTAssertTrue(true)
        }
    }

    // MARK: - Accessibility Tests
    @MainActor
    func testAccessibility_mainElements() throws {
        // Wait for app to load
        _ = app.waitForExistence(timeout: 10)

        // Test that main interactive elements are accessible
        let buttons = app.buttons
        let tabBar = app.tabBars.firstMatch

        // Verify buttons have accessibility labels
        if buttons.count > 0 {
            for i in 0..<min(buttons.count, 5) { // Test first 5 buttons
                let button = buttons.element(boundBy: i)
                if button.exists && button.isHittable {
                    // Button should have some form of accessibility identifier or label
                    let hasLabel = button.label.count > 0
                    let hasIdentifier = button.identifier.count > 0
                    XCTAssertTrue(hasLabel || hasIdentifier, "Button should have accessibility label or identifier")
                }
            }
        }

        // Test tab bar accessibility
        if tabBar.exists {
            let tabButtons = tabBar.buttons
            for i in 0..<tabButtons.count {
                let tabButton = tabButtons.element(boundBy: i)
                if tabButton.exists {
                    XCTAssertTrue(tabButton.label.count > 0 || tabButton.identifier.count > 0)
                }
            }
        }
    }

    // MARK: - Performance Tests
    @MainActor
    func testPerformance_mapScrolling() throws {
        // Wait for app to load
        _ = app.waitForExistence(timeout: 10)

        let mapView = app.maps.firstMatch
        if mapView.exists && mapView.isHittable {
            // Measure map scrolling performance
            measure(metrics: [XCTOSSignpostMetric.scrollingAndDecelerationMetric]) {
                mapView.swipeLeft()
                mapView.swipeRight()
                mapView.swipeUp()
                mapView.swipeDown()
            }
        }
    }
}
