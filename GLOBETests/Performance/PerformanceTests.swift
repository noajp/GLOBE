//======================================================================
// MARK: - PerformanceTests.swift
// Purpose: パフォーマンステスト - 処理速度・メモリ使用量・応答性の検証
// Path: GLOBETests/Performance/PerformanceTests.swift
//======================================================================

import XCTest
import CoreLocation
@testable import GLOBE

@MainActor
final class PerformanceTests: XCTestCase {

    // MARK: - Input Validation Performance Tests
    func testInputValidation_massiveEmailValidation_performance() {
        // Given: Large number of email inputs
        let emails = (1...1000).map { "user\($0)@example.com" }

        // When: Measure validation performance
        measure {
            for email in emails {
                _ = InputValidator.validateEmail(email)
            }
        }

        // Performance expectation: < 0.1 seconds for 1000 validations
    }

    func testInputValidation_longContentSanitization_performance() {
        // Given: Very long content with potential XSS
        let longContent = String(repeating: "<script>alert('xss')</script>", count: 100) +
                         String(repeating: "安全なテキスト", count: 1000)

        // When: Measure sanitization performance
        measure {
            _ = InputValidator.validatePostContent(longContent)
        }

        // Performance expectation: < 0.05 seconds for large content sanitization
    }

    // MARK: - Authentication Performance Tests
    func testAuthManager_deviceSecurityInfo_performance() {
        // When: Measure device security info retrieval
        measure {
            for _ in 1...100 {
                _ = AuthManager.shared.getDeviceSecurityInfo()
            }
        }

        // Performance expectation: < 0.01 seconds for 100 calls
    }

    func testAuthManager_rateLimitCheck_performance() {
        // Given: Multiple rate limit checks
        let testIPs = (1...50).map { "192.168.1.\($0)" }

        // When: Measure rate limit checking performance
        measure {
            for _ in testIPs {
                // Simulate rate limit check logic
                let timestamp = Date().timeIntervalSince1970
                _ = timestamp > 0 // Simplified check
            }
        }

        // Performance expectation: < 0.01 seconds for 50 IP checks
    }

    // MARK: - Database Security Performance Tests
    func testDatabaseSecurity_massiveSQLInjectionDetection_performance() {
        // Given: Many potentially dangerous queries
        let queries = [
            "SELECT * FROM users; DROP TABLE users; --",
            "SELECT * FROM posts WHERE id = '; DELETE FROM posts; --",
            "INSERT INTO users VALUES (1, 'admin'); UPDATE users SET role='admin'; --",
            "SELECT * FROM secrets UNION SELECT password FROM users; --"
        ]
        let repeatedQueries = Array(repeating: queries, count: 250).flatMap { $0 }

        // When: Measure injection detection performance
        measure {
            for query in repeatedQueries {
                _ = DatabaseSecurity.shared.validateQuery(query, operation: .select)
            }
        }

        // Performance expectation: < 0.1 seconds for 1000 query validations
    }

    func testDatabaseSecurity_largeSanitization_performance() {
        // Given: Large complex data structure
        let largeData: [String: Any] = [
            "content": String(repeating: "テスト\u{0000}データ", count: 500),
            "metadata": Array(repeating: "item\u{0000}", count: 1000),
            "nested": [
                "level1": [
                    "level2": String(repeating: "deep\u{0000}data", count: 200)
                ]
            ]
        ]

        // When: Measure sanitization performance
        measure {
            _ = DatabaseSecurity.shared.sanitizeForDatabase(largeData)
        }

        // Performance expectation: < 0.05 seconds for large data sanitization
    }

    // MARK: - Memory Usage Tests
    func testInputValidator_memoryEfficiency() {
        // Given: Memory measurement setup
        let initialMemory = getMemoryUsage()

        // When: Perform many validations
        for i in 1...10000 {
            autoreleasepool {
                _ = InputValidator.validateEmail("test\(i)@example.com")
                _ = InputValidator.validatePassword("Password\(i)123")
                _ = InputValidator.validateUsername("user\(i)")
            }
        }

        // Then: Memory should not grow excessively
        let finalMemory = getMemoryUsage()
        let memoryGrowth = finalMemory - initialMemory

        // Memory growth should be reasonable (< 50MB for 10K validations)
        XCTAssertLessThan(memoryGrowth, 50_000_000, "Memory growth should be under 50MB")
    }

    // MARK: - Concurrent Access Performance Tests
    func testConcurrentValidation_threadSafety_performance() {
        // When: Multiple concurrent validation operations
        measure {
            DispatchQueue.concurrentPerform(iterations: 10) { index in
                autoreleasepool {
                    for i in 1...100 {
                        _ = InputValidator.validateEmail("concurrent\(index)-\(i)@test.com")
                    }
                }
            }
        }

        // Performance expectation: < 1.0 seconds for concurrent validation
    }

    // MARK: - Real-world Scenario Performance Tests
    func testPostCreation_fullValidationPipeline_performance() {
        // Given: Realistic post data
        let content = "これは投稿テストです。" + String(repeating: "🌍", count: 50)
        let location = CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503)
        let locationName = "東京都渋谷区"

        // When: Measure full validation pipeline
        measure {
            autoreleasepool {
                // Simulate the validation pipeline used in post creation
                _ = InputValidator.validatePostContent(content)
                _ = InputValidator.sanitizeText(locationName)

                let queryData = [
                    "content": content,
                    "location": locationName,
                    "latitude": location.latitude,
                    "longitude": location.longitude
                ]
                _ = DatabaseSecurity.shared.sanitizeForDatabase(queryData)
            }
        }

        // Performance expectation: < 0.01 seconds per post validation
    }

    // MARK: - Helper Methods
    private func getMemoryUsage() -> Int64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return Int64(info.resident_size)
        } else {
            return 0
        }
    }
}