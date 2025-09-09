//======================================================================
// MARK: - AppSettings.swift
// Purpose: Centralized user settings (posting/privacy preferences)
// Path: GLOBE/Managers/AppSettings.swift
//======================================================================

import Foundation
import Combine

@MainActor
class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var defaultAnonymousPosting: Bool {
        didSet { UserDefaults.standard.set(defaultAnonymousPosting, forKey: Keys.anonymousPosting) }
    }

    @Published var showLocationNameOnPost: Bool {
        didSet { UserDefaults.standard.set(showLocationNameOnPost, forKey: Keys.showLocationName) }
    }

    @Published var showMyLocationOnMap: Bool {
        didSet { UserDefaults.standard.set(showMyLocationOnMap, forKey: Keys.showMyLocationOnMap) }
    }

    private struct Keys {
        static let anonymousPosting = "app_settings_default_anonymous_posting"
        static let showLocationName = "app_settings_show_location_name"
        static let showMyLocationOnMap = "app_settings_show_my_location_on_map"
    }

    private init() {
        // Defaults: anonymous off, show location name on
        let anon = UserDefaults.standard.object(forKey: Keys.anonymousPosting) as? Bool ?? false
        let show = UserDefaults.standard.object(forKey: Keys.showLocationName) as? Bool ?? true
        let showMine = UserDefaults.standard.object(forKey: Keys.showMyLocationOnMap) as? Bool ?? false
        self.defaultAnonymousPosting = anon
        self.showLocationNameOnPost = show
        self.showMyLocationOnMap = showMine
    }
}
