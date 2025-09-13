//======================================================================
// MARK: - TestHelpers.swift
// Purpose: 共通テストユーティリティ（アサーション補助など）
// Path: GLOBETests/Helpers/TestHelpers.swift
//======================================================================

import XCTest

// MARK: - ValidationResult ヘルパ
@testable import GLOBE

extension ValidationResult {
    var unwrappedValue: String {
        switch self {
        case .valid(let v): return v
        case .invalid(let message):
            XCTFail("ValidationResult invalid: \(message)")
            return ""
        }
    }
}

