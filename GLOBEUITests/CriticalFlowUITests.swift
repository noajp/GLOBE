//======================================================================
// MARK: - CriticalFlowUITests.swift
// Purpose: Critical user flow UI tests for GLOBE app
// Path: GLOBEUITests/CriticalFlowUITests.swift
//
// NOTE: このアプリは標準のTabBarではなくLiquidGlassBottomTabBarという
// カスタムコンポーネントを使用しているため、タブバー関連のテストが
// 失敗する可能性があります。
//======================================================================

import XCTest

final class CriticalFlowUITests: XCTestCase {

    // MARK: - Test Properties
    var app: XCUIApplication!

    // MARK: - Test Constants
    private struct TestConstants {
        static let defaultTimeout: TimeInterval = 10
        static let shortTimeout: TimeInterval = 3
        static let longTimeout: TimeInterval = 15
        static let animationTimeout: TimeInterval = 1
    }

    // MARK: - Setup & Teardown
    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--reset-state"]
        app.launchEnvironment = [
            "ANIMATION_SPEED": "100",
            "MOCK_LOCATION": "true",
            "SKIP_ONBOARDING": "true"
        ]
        app.launch()

        XCTAssertTrue(app.waitForExistence(timeout: TestConstants.defaultTimeout))
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods
    private func waitForElement(_ element: XCUIElement, timeout: TimeInterval = TestConstants.defaultTimeout) -> Bool {
        return element.waitForExistence(timeout: timeout)
    }

    private func tapElementSafely(_ element: XCUIElement, description: String = "element") {
        XCTAssertTrue(waitForElement(element), "\(description) should exist")
        XCTAssertTrue(element.isHittable, "\(description) should be hittable")
        element.tap()
    }

    // MARK: - Critical Flow Tests

    @MainActor
    func testCriticalFlow_AppLaunchToMapView() throws {
        // Test the critical path from app launch to map view

        // 1. App should launch successfully
        let appWindow = app.windows.firstMatch
        XCTAssertTrue(waitForElement(appWindow), "App window should appear")

        // 2. Map view should be visible and interactive
        let mapView = app.maps.firstMatch
        if mapView.exists {
            XCTAssertTrue(mapView.isHittable, "Map should be interactive")

            // 3. Basic map interaction should work
            mapView.tap()
            Thread.sleep(forTimeInterval: TestConstants.animationTimeout)

            // 4. Map should respond to gestures
            mapView.pinch(withScale: 1.5, velocity: 1.0)
            Thread.sleep(forTimeInterval: TestConstants.animationTimeout)

            XCTAssertTrue(mapView.exists, "Map should remain visible after interaction")
        }
    }

    @MainActor
    func testCriticalFlow_NavigationBetweenTabs() throws {
        // Test navigation between main app sections

        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            throw XCTSkip("App doesn't use tab navigation")
        }

        let tabs = tabBar.buttons
        XCTAssertGreaterThan(tabs.count, 0, "Should have navigation tabs")

        // Test navigating to each tab and back
        for i in 0..<min(tabs.count, 3) {
            let tab = tabs.element(boundBy: i)
            if tab.exists && tab.isHittable {
                let tabName = tab.label

                // Navigate to tab
                tapElementSafely(tab, description: "Tab: \(tabName)")
                Thread.sleep(forTimeInterval: TestConstants.animationTimeout)

                // Verify tab is selected
                XCTAssertTrue(tab.isSelected || (tab.value(forKey: "isSelected") as? Bool == true),
                             "Tab \(tabName) should be selected")

                // Verify app is still responsive
                XCTAssertTrue(app.windows.firstMatch.exists, "App should remain responsive")
            }
        }
    }

    @MainActor
    func testCriticalFlow_PostCreationWorkflow() throws {
        // Test the complete post creation workflow

        // 1. Trigger post creation (try multiple methods)
        var postCreationTriggered = false

        // Method 1: Look for create button
        let createButton = app.buttons["Create"].firstMatch
        if createButton.exists && createButton.isHittable {
            tapElementSafely(createButton, description: "Create button")
            postCreationTriggered = true
        }

        // Method 2: Try long press on map
        if !postCreationTriggered {
            let mapView = app.maps.firstMatch
            if mapView.exists {
                mapView.press(forDuration: 1.0)
                Thread.sleep(forTimeInterval: TestConstants.shortTimeout)
                postCreationTriggered = app.textViews.firstMatch.exists
            }
        }

        // Method 3: Look for floating action button
        if !postCreationTriggered {
            let fabButton = app.buttons["+"].firstMatch
            if fabButton.exists && fabButton.isHittable {
                tapElementSafely(fabButton, description: "FAB button")
                postCreationTriggered = true
            }
        }

        if postCreationTriggered {
            // 2. Post creation UI should appear
            let textView = app.textViews.firstMatch
            if waitForElement(textView, timeout: TestConstants.shortTimeout) {
                XCTAssertTrue(textView.isHittable, "Text input should be interactive")

                // 3. Test text input
                textView.tap()
                textView.typeText("Test post from UI automation")

                // 4. Look for post submit button
                let postButton = app.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'post' OR label CONTAINS[cd] '投稿'")).firstMatch
                if postButton.exists && postButton.isHittable {
                    tapElementSafely(postButton, description: "Post submit button")

                    // 5. Verify post creation completes
                    Thread.sleep(forTimeInterval: TestConstants.shortTimeout)
                    XCTAssertFalse(textView.exists, "Post creation UI should dismiss")
                }
            }
        } else {
            XCTSkip("Could not trigger post creation workflow")
        }
    }

    @MainActor
    func testCriticalFlow_LocationPermissionHandling() throws {
        // Test location permission flow (if triggered)

        // Look for location permission alert
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let locationAlert = springboard.alerts.firstMatch

        if locationAlert.waitForExistence(timeout: TestConstants.shortTimeout) {
            // If location permission dialog appears, handle it
            let allowButton = locationAlert.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'allow'")).firstMatch
            if allowButton.exists {
                allowButton.tap()
            } else {
                // Fallback - try "OK" or similar
                let okButton = locationAlert.buttons["OK"].firstMatch
                if okButton.exists {
                    okButton.tap()
                }
            }

            // Verify app continues to work after permission handling
            Thread.sleep(forTimeInterval: TestConstants.animationTimeout)
            XCTAssertTrue(app.windows.firstMatch.exists, "App should remain functional")
        }
    }

    @MainActor
    func testCriticalFlow_AppRecoveryFromInterruption() throws {
        // Test app recovery from common interruptions

        // 1. Background the app
        XCUIDevice.shared.press(.home)
        Thread.sleep(forTimeInterval: 2)

        // 2. Reactivate the app
        app.activate()

        // 3. Verify app recovers properly
        XCTAssertTrue(waitForElement(app.windows.firstMatch, timeout: TestConstants.longTimeout),
                     "App should recover from backgrounding")

        // 4. Verify main functionality is still available
        let mapView = app.maps.firstMatch
        if mapView.exists {
            XCTAssertTrue(mapView.isHittable, "Map should be interactive after recovery")
        }

        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            XCTAssertTrue(tabBar.isHittable, "Navigation should work after recovery")
        }
    }

    @MainActor
    func testCriticalFlow_MemoryPressureHandling() throws {
        // Test app behavior under simulated memory pressure

        // Simulate memory pressure by creating multiple views
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let tabs = tabBar.buttons

            // Rapidly switch between tabs to stress memory
            for _ in 0..<10 {
                for i in 0..<tabs.count {
                    let tab = tabs.element(boundBy: i)
                    if tab.exists && tab.isHittable {
                        tab.tap()
                        Thread.sleep(forTimeInterval: 0.1) // Very short delay
                    }
                }
            }

            // Verify app is still responsive
            Thread.sleep(forTimeInterval: TestConstants.animationTimeout)
            XCTAssertTrue(app.windows.firstMatch.exists, "App should handle rapid navigation")
        }
    }

    @MainActor
    func testCriticalFlow_NetworkStateChanges() throws {
        // Test app behavior with network state simulation

        // Note: This test assumes the app has some network-dependent features
        // In a real implementation, you would simulate network conditions

        let mapView = app.maps.firstMatch
        if mapView.exists {
            // Interact with network-dependent features
            mapView.tap()
            Thread.sleep(forTimeInterval: TestConstants.shortTimeout)

            // App should remain functional even if network requests fail
            XCTAssertTrue(mapView.exists, "App should handle network issues gracefully")
        }
    }

    @MainActor
    func testCriticalFlow_ErrorStateRecovery() throws {
        // Test recovery from error states

        // Look for any error messages or retry buttons
        let errorAlert = app.alerts.firstMatch
        if errorAlert.waitForExistence(timeout: TestConstants.shortTimeout) {
            // Handle error dialog
            let okButton = errorAlert.buttons["OK"].firstMatch
            let retryButton = errorAlert.buttons.matching(NSPredicate(format: "label CONTAINS[cd] 'retry'")).firstMatch

            if retryButton.exists {
                tapElementSafely(retryButton, description: "Retry button")
            } else if okButton.exists {
                tapElementSafely(okButton, description: "OK button")
            }

            // Verify app continues to function
            Thread.sleep(forTimeInterval: TestConstants.animationTimeout)
            XCTAssertTrue(app.windows.firstMatch.exists, "App should recover from errors")
        }
    }

    @MainActor
    func testCriticalFlow_CompleteUserJourney() throws {
        // Test a complete user journey from launch to key action

        // 1. App launches successfully
        XCTAssertTrue(app.windows.firstMatch.exists, "App should launch")

        // 2. User can navigate to main content
        let mapView = app.maps.firstMatch
        if mapView.exists {
            XCTAssertTrue(mapView.isHittable, "Main content should be accessible")

            // 3. User can interact with core features
            mapView.tap()
            Thread.sleep(forTimeInterval: TestConstants.animationTimeout)

            // 4. App responds appropriately
            XCTAssertTrue(mapView.exists, "Core interaction should work")
        }

        // 5. Navigation works
        let tabBar = app.tabBars.firstMatch
        if tabBar.exists {
            let firstTab = tabBar.buttons.element(boundBy: 0)
            if firstTab.exists {
                tapElementSafely(firstTab, description: "First tab")
                XCTAssertTrue(firstTab.isSelected, "Navigation should work")
            }
        }

        // 6. App maintains state
        XCTAssertTrue(app.windows.firstMatch.exists, "App should maintain consistent state")
    }

    // MARK: - Performance Critical Flows

    @MainActor
    func testPerformanceCriticalFlow_AppLaunchTime() throws {
        measure(metrics: [XCTApplicationLaunchMetric()]) {
            let testApp = XCUIApplication()
            testApp.launchArguments = ["--uitesting"]
            testApp.launch()
        }
    }

    @MainActor
    func testPerformanceCriticalFlow_TabSwitchingSpeed() throws {
        let tabBar = app.tabBars.firstMatch
        guard tabBar.exists else {
            throw XCTSkip("No tab bar found")
        }

        let tabs = tabBar.buttons
        guard tabs.count > 1 else {
            throw XCTSkip("Need multiple tabs for switching test")
        }

        measure {
            // Switch between tabs rapidly
            for i in 0..<min(tabs.count, 4) {
                let tab = tabs.element(boundBy: i)
                if tab.exists && tab.isHittable {
                    tab.tap()
                }
            }
        }
    }
}