//======================================================================
// MARK: - Store.swift
// Purpose: Redux-like store for centralized state management
// Path: GLOBE/Core/State/Store.swift
//======================================================================

import Foundation
import Combine
import SwiftUI

// MARK: - Store Protocol

protocol StoreProtocol: ObservableObject {
    associatedtype State
    associatedtype Action

    var state: State { get }
    func dispatch(_ action: Action)
    func dispatch(_ actions: [Action])
}

// MARK: - App Store

@MainActor
class AppStore: StoreProtocol, ObservableObject {
    @Published private(set) var state: AppState

    private let reducer: (AppState, Action) -> AppState
    private var middleware: [Middleware] = []
    private var subscribers: [String: (AppState) -> Void] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Store Analytics
    private var actionHistory: [ActionHistoryEntry] = []
    private let maxHistorySize = 100
    private var stateChangeCount = 0

    init(
        initialState: AppState? = nil,
        reducer: @escaping @MainActor (AppState, Action) -> AppState = AppReducer.reduceAndValidate,
        middleware: [Middleware] = []
    ) {
        self.state = initialState ?? AppState.initial
        self.reducer = reducer
        self.middleware = middleware

        setupDefaultMiddleware()
        logStoreInitialization()
    }

    // MARK: - Action Dispatch

    func dispatch(_ action: Action) {
        let oldState = state

        // Apply middleware before reduction
        var finalAction = action
        for middleware in middleware {
            finalAction = middleware.process(action: finalAction, state: state, dispatch: self.dispatch)
        }

        // Log action for debugging
        finalAction.log()

        // Apply reducer
        let newState = reducer(state, finalAction)

        // Update state if changed
        if newState != oldState {
            state = newState
            stateChangeCount += 1

            // Record in history
            recordActionInHistory(action: finalAction, oldState: oldState, newState: newState)

            // Notify subscribers
            notifySubscribers(newState: newState)

            SecureLogger.shared.info("State updated - action: \(finalAction.type), stateChanges: \(stateChangeCount)")
        }
    }

    func dispatch(_ actions: [Action]) {
        for action in actions {
            dispatch(action)
        }
    }

    // MARK: - Subscription Management

    func subscribe(id: String, callback: @escaping (AppState) -> Void) {
        subscribers[id] = callback
    }

    func unsubscribe(id: String) {
        subscribers.removeValue(forKey: id)
    }

    // MARK: - State Observation

    var statePublisher: AnyPublisher<AppState, Never> {
        $state.eraseToAnyPublisher()
    }

    // MARK: - Computed State Selectors

    var isAuthenticated: Bool {
        state.isAuthenticated
    }

    var currentUser: AppUser? {
        state.currentUser
    }

    var posts: [Post] {
        state.allPosts
    }

    var userPosts: [Post] {
        state.postsState.userPosts
    }

    var visiblePosts: [Post] {
        state.visiblePosts
    }

    var userProfile: UserProfile? {
        state.userState.profile
    }

    var selectedTab: TabSelection {
        state.uiState.selectedTab
    }

    var isLoading: Bool {
        state.authState.isLoading ||
        state.postsState.isLoading ||
        state.userState.isLoading
    }

    var hasError: Bool {
        state.authState.error != nil ||
        state.postsState.error != nil ||
        state.userState.error != nil
    }

    // MARK: - Middleware Setup

    private func setupDefaultMiddleware() {
        // Add logging middleware
        middleware.append(LoggingMiddleware())

        // Add persistence middleware for important state changes
        middleware.append(PersistenceMiddleware())

        // Add analytics middleware
        middleware.append(AnalyticsMiddleware())
    }

    // MARK: - Private Methods

    private func notifySubscribers(newState: AppState) {
        for (_, callback) in subscribers {
            callback(newState)
        }
    }

    private func recordActionInHistory(action: Action, oldState: AppState, newState: AppState) {
        let entry = ActionHistoryEntry(
            action: action,
            timestamp: action.timestamp,
            oldState: oldState,
            newState: newState
        )

        actionHistory.append(entry)

        // Keep history size manageable
        if actionHistory.count > maxHistorySize {
            actionHistory.removeFirst(actionHistory.count - maxHistorySize)
        }
    }

    private func logStoreInitialization() {
        SecureLogger.shared.info("AppStore initialized - middlewareCount: \(middleware.count), initialState: AppState.initial")
    }

    // MARK: - Debug Methods

    #if DEBUG
    func getActionHistory() -> [ActionHistoryEntry] {
        return actionHistory
    }

    func printStateTree() {
        print("Current App State:")
        print(state.description)
    }

    func resetState() {
        dispatch(AppAction.resetState)
    }
    #endif
}

// MARK: - Action History

struct ActionHistoryEntry {
    let action: Action
    let timestamp: Date
    let oldState: AppState
    let newState: AppState

    var actionType: String {
        action.type
    }
}

// MARK: - Middleware Protocol

protocol Middleware {
    func process(action: Action, state: AppState, dispatch: @escaping (Action) -> Void) -> Action
}

// MARK: - Logging Middleware

struct LoggingMiddleware: Middleware {
    func process(action: Action, state: AppState, dispatch: @escaping (Action) -> Void) -> Action {
        SecureLogger.shared.info("Middleware: Processing action - action: \(action.type), timestamp: \(action.timestamp.ISO8601Format())")
        return action
    }
}

// MARK: - Persistence Middleware

struct PersistenceMiddleware: Middleware {
    private let persistentActions: Set<String> = [
        "AUTH_SIGN_IN_SUCCESS",
        "AUTH_SIGN_UP_SUCCESS",
        "AUTH_SIGN_OUT",
        "USER_UPDATE_PROFILE_SUCCESS"
    ]

    func process(action: Action, state: AppState, dispatch: @escaping (Action) -> Void) -> Action {
        if persistentActions.contains(action.type) {
            // Save important state changes to UserDefaults
            Task {
                await persistStateChange(action: action, state: state)
            }
        }
        return action
    }

    private func persistStateChange(action: Action, state: AppState) async {
        switch action.type {
        case "AUTH_SIGN_IN_SUCCESS", "AUTH_SIGN_UP_SUCCESS":
            if let user = state.currentUser {
                UserDefaults.standard.set(try? JSONEncoder().encode(user), forKey: "cached_user")
            }

        case "AUTH_SIGN_OUT":
            UserDefaults.standard.removeObject(forKey: "cached_user")

        case "USER_UPDATE_PROFILE_SUCCESS":
            if let profile = state.userState.profile {
                UserDefaults.standard.set(try? JSONEncoder().encode(profile), forKey: "cached_profile")
            }

        default:
            break
        }
    }
}

// MARK: - Analytics Middleware

struct AnalyticsMiddleware: Middleware {
    func process(action: Action, state: AppState, dispatch: @escaping (Action) -> Void) -> Action {
        // Track important user actions for analytics
        let trackableActions: Set<String> = [
            "AUTH_SIGN_IN_SUCCESS",
            "POSTS_CREATE_SUCCESS",
            "POSTS_TOGGLE_LIKE",
            "MAP_SELECT_POST"
        ]

        if trackableActions.contains(action.type) {
            SecureLogger.shared.info("Analytics: User action tracked - action: \(action.type), timestamp: \(action.timestamp.ISO8601Format())")
        }

        return action
    }
}

// MARK: - Global Store Instance

extension AppStore {
    static let shared = AppStore()
}

// MARK: - SwiftUI Integration

@MainActor
struct StoreProvider<Content: View>: View {
    let store: AppStore
    let content: Content

    @MainActor init(store: AppStore? = nil, @ViewBuilder content: () -> Content) {
        if let store = store {
            self.store = store
        } else {
            self.store = AppStore.shared
        }
        self.content = content()
    }

    var body: some View {
        content
            .environmentObject(store)
    }
}

// MARK: - Environment Key

private struct StoreEnvironmentKey: EnvironmentKey {
    static let defaultValue: AppStore = .shared
}

extension EnvironmentValues {
    var store: AppStore {
        get { self[StoreEnvironmentKey.self] }
        set { self[StoreEnvironmentKey.self] = newValue }
    }
}