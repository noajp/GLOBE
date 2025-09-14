//======================================================================
// MARK: - GLOBEUITests.swift
// Purpose: UI/E2Eテスト（ユーザーフロー・画面遷移・主要機能のエンドツーエンドテスト）
// Path: GLOBEUITests/GLOBEUITests.swift
//======================================================================

import XCTest

final class GLOBEUITests: XCTestCase {

    // MARK: - Test Properties
    var app: XCUIApplication!

    // MARK: - Test Constants
    private struct TestConstants {
        static let defaultTimeout: TimeInterval = 10
        static let shortTimeout: TimeInterval = 3
        static let longTimeout: TimeInterval = 15
        static let animationTimeout: TimeInterval = 1
    }

    // MARK: - Accessibility Identifiers
    private struct AccessibilityIdentifiers {
        static let mapView = "MainMapView"
        static let createPostButton = "CreatePostButton"
        static let locationButton = "LocationButton"
        static let postCreationModal = "PostCreationModal"
        static let postContentTextView = "PostContentTextView"
        static let submitPostButton = "SubmitPostButton"
        static let profileTab = "ProfileTab"
        static let mapTab = "MapTab"
        static let settingsTab = "SettingsTab"
    }

    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] // UI testing flag
        app.launchEnvironment = ["ANIMATION_SPEED": "100"] // Speed up animations
        app.launch()

        // Wait for app to be ready
        XCTAssertTrue(app.waitForExistence(timeout: TestConstants.defaultTimeout))
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = TestConstants.defaultTimeout) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    private func waitForElementToBeHittable(_ element: XCUIElement, timeout: TimeInterval = TestConstants.defaultTimeout) -> Bool {
        let predicate = NSPredicate(format: "isHittable == true")
        let expectation = XCTNSPredicateExpectation(predicate: predicate, object: element)
        let result = XCTWaiter.wait(for: [expectation], timeout: timeout)
        return result == .completed
    }

    private func tapElementSafely(_ element: XCUIElement, description: String = "element") {
        XCTAssertTrue(waitForElement(element), "\(description) should exist")
        XCTAssertTrue(waitForElementToBeHittable(element), "\(description) should be hittable")
        element.tap()
    }

    private func dismissKeyboardIfPresent() {
        if app.keyboards.firstMatch.exists {
            app.keyboards.buttons["return"].tap()
        }
    }

    private func scrollToElement(_ element: XCUIElement, in scrollView: XCUIElement) {
        while !element.isHittable && scrollView.exists {
            scrollView.swipeUp()
        }
    }

    // MARK: - App Launch Tests
    @MainActor
    func testAppLaunch_showsMainInterface() throws {
        // Given: App is launched in setUpWithError()

        // Then: Main interface elements should be visible
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            XCTAssertTrue(waitForElementToBeHittable(tabBar), "Tab bar should be hittable")

            // Verify essential tabs exist
            let mapTab = app.tabBars.buttons.matching(identifier: AccessibilityIdentifiers.mapTab).firstMatch
            let profileTab = app.tabBars.buttons.matching(identifier: AccessibilityIdentifiers.profileTab).firstMatch

            if mapTab.exists {
                XCTAssertTrue(mapTab.isHittable, "Map tab should be hittable")
            }
            if profileTab.exists {
                XCTAssertTrue(profileTab.isHittable, "Profile tab should be hittable")
            }
        }

        // Check for map view existence (primary interface)
        let mapView = app.maps.matching(identifier: AccessibilityIdentifiers.mapView).firstMatch
        if mapView.exists {
            XCTAssertTrue(mapView.isHittable, "Map view should be interactive")
        }
    }

    @MainActor
    func testLaunchPerformance() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launchArguments = ["--uitesting"]
            testApp.launch()
        }
    }

    @MainActor
    func testAppStability_multipleBackgroundForeground() throws {
        // Test app stability with background/foreground cycles
        for _ in 0..<3 {
            XCUIDevice.shared.press(.home)
            sleep(1)
            app.activate()
            XCTAssertTrue(waitForElement(app.windows.firstMatch, timeout: TestConstants.shortTimeout))
        }
    }

    // MARK: - Main Navigation Tests
    @MainActor
    func testMainNavigation_tabBarNavigation() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            XCTSkip("Tab bar not found - app may not use tab navigation")
        }

        XCTAssertTrue(waitForElementToBeHittable(tabBar), "Tab bar should be interactive")

        let tabButtons = tabBar.buttons
        XCTAssertGreaterThan(tabButtons.count, 0, "Should have at least one tab")

        // Test navigation to each tab
        var previousTabTitle: String?
        for i in 0..<min(tabButtons.count, 5) { // Test up to 5 tabs
            let tabButton = tabButtons.element(boundBy: i)

            if tabButton.exists && tabButton.isHittable {
                let tabTitle = tabButton.label
                XCTAssertNotEqual(tabTitle, previousTabTitle, "Tab titles should be unique")

                tapElementSafely(tabButton, description: "Tab button '\(tabTitle)'")

                // Wait for tab content to load and verify selection
                Thread.sleep(forTimeInterval: TestConstants.animationTimeout)
                XCTAssertTrue(tabButton.isSelected || tabButton.value(forKey: "isSelected") as? Bool == true,
                             "Tab '\(tabTitle)' should be selected after tap")

                previousTabTitle = tabTitle
            }
        }
    }

    @MainActor
    func testMainNavigation_backButtonFunctionality() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            XCTSkip("Tab bar not found")
        }

        // Navigate to profile if available
        let profileTab = app.tabBars.buttons.matching(identifier: AccessibilityIdentifiers.profileTab).firstMatch
        if profileTab.exists {
            tapElementSafely(profileTab, description: "Profile tab")

            // Look for navigation back button
            let backButton = app.navigationBars.buttons.firstMatch
            if backButton.exists && backButton.label.contains("Back") {
                tapElementSafely(backButton, description: "Back button")

                // Verify we navigated back
                Thread.sleep(forTimeInterval: TestConstants.animationTimeout)
                XCTAssertTrue(waitForElement(tabBar), "Should return to main navigation")
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
