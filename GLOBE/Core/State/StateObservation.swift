//======================================================================
// MARK: - StateObservation.swift
// Purpose: Optimized Combine operators for state observation
// Path: GLOBE/Core/State/StateObservation.swift
//======================================================================

import Foundation
import Combine
import SwiftUI
import CoreLocation

// MARK: - State Selectors

protocol StateSelector {
    associatedtype Input
    associatedtype Output

    func select(_ input: Input) -> Output
}

// MARK: - Store State Selectors

struct AppStateSelectors {
    // MARK: - Auth Selectors
    static let isAuthenticated = Selector<AppState, Bool> { state in
        state.authState.isAuthenticated
    }

    static let currentUser = Selector<AppState, AppUser?> { state in
        state.authState.currentUser
    }

    static let authError = Selector<AppState, AppError?> { state in
        state.authState.error
    }

    static let isAuthLoading = Selector<AppState, Bool> { state in
        state.authState.isLoading
    }

    // MARK: - Posts Selectors
    static let allPosts = Selector<AppState, [Post]> { state in
        state.postsState.posts
    }

    static let userPosts = Selector<AppState, [Post]> { state in
        state.postsState.userPosts
    }

    static let selectedPost = Selector<AppState, Post?> { state in
        state.postsState.selectedPost
    }

    static let isPostsLoading = Selector<AppState, Bool> { state in
        state.postsState.isLoading
    }

    // MARK: - Map Selectors
    static let userLocation = Selector<AppState, CLLocationCoordinate2D?> { state in
        state.mapState.userLocation
    }

    static let visiblePosts = Selector<AppState, [Post]> { state in
        state.mapState.visiblePosts
    }

    static let mapRegion = Selector<AppState, MapRegion> { state in
        state.mapState.region
    }

    static let isTrackingUser = Selector<AppState, Bool> { state in
        state.mapState.isTrackingUser
    }

    // MARK: - User Selectors
    static let userProfile = Selector<AppState, UserProfile?> { state in
        state.userState.profile
    }

    static let userStories = Selector<AppState, [Story]> { state in
        state.userState.stories
    }

    // MARK: - UI Selectors
    static let selectedTab = Selector<AppState, TabSelection> { state in
        state.uiState.selectedTab
    }

    static let showingAuth = Selector<AppState, Bool> { state in
        state.uiState.showingAuth
    }

    static let showingCreatePost = Selector<AppState, Bool> { state in
        state.uiState.showingCreatePost
    }

    // MARK: - Composed Selectors
    static let authAndUIState = ComposedSelector(
        isAuthenticated,
        showingAuth,
        combiner: { auth, showAuth in
            (isAuthenticated: auth, shouldShowAuth: showAuth)
        }
    )

    static let postsAndMap = ComposedSelector(
        allPosts,
        visiblePosts,
        combiner: { posts, visible in
            (allPosts: posts, visiblePosts: visible, totalCount: posts.count)
        }
    )
}

// MARK: - Selector Implementation

struct Selector<State, Output>: StateSelector {
    private let selector: (State) -> Output

    init(_ selector: @escaping (State) -> Output) {
        self.selector = selector
    }

    func select(_ state: State) -> Output {
        return selector(state)
    }
}

struct ComposedSelector<State, A, B, Output> {
    private let selectorA: Selector<State, A>
    private let selectorB: Selector<State, B>
    private let combiner: (A, B) -> Output

    init(
        _ selectorA: Selector<State, A>,
        _ selectorB: Selector<State, B>,
        combiner: @escaping (A, B) -> Output
    ) {
        self.selectorA = selectorA
        self.selectorB = selectorB
        self.combiner = combiner
    }

    func select(_ state: State) -> Output {
        let a = selectorA.select(state)
        let b = selectorB.select(state)
        return combiner(a, b)
    }
}

// Convenience initializer for tuple-based composed selectors
extension ComposedSelector {
    init<SA: StateSelector, SB: StateSelector>(
        _ keyPathA: KeyPath<ComposedSelector, SA>,
        _ keyPathB: KeyPath<ComposedSelector, SB>,
        combiner: @escaping (SA.Output, SB.Output) -> Output
    ) where SA.Input == State, SB.Input == State, A == SA.Output, B == SB.Output {
        fatalError("This initializer is for demonstration - use the named parameter version")
    }

    init<SA: StateSelector, SB: StateSelector>(
        _ selectorA: SA,
        _ selectorB: SB,
        combiner: @escaping (SA.Output, SB.Output) -> Output
    ) where SA.Input == State, SB.Input == State, A == SA.Output, B == SB.Output {
        self.selectorA = Selector { state in selectorA.select(state) }
        self.selectorB = Selector { state in selectorB.select(state) }
        self.combiner = combiner
    }
}

// MARK: - Store Extensions for Optimized Observation

extension AppStore {
    // MARK: - Selective State Observation

    func observe<T: Equatable>(_ selector: Selector<AppState, T>) -> AnyPublisher<T, Never> {
        return $state
            .map { selector.select($0) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    func observe<T>(_ selector: Selector<AppState, T>) -> AnyPublisher<T, Never> {
        return $state
            .map { selector.select($0) }
            .eraseToAnyPublisher()
    }

    // MARK: - Optimized Publishers

    var authStatePublisher: AnyPublisher<AuthState, Never> {
        return $state
            .map(\.authState)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var postsStatePublisher: AnyPublisher<PostsState, Never> {
        return $state
            .map(\.postsState)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var mapStatePublisher: AnyPublisher<MapState, Never> {
        return $state
            .map(\.mapState)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var userStatePublisher: AnyPublisher<UserState, Never> {
        return $state
            .map(\.userState)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var uiStatePublisher: AnyPublisher<UIState, Never> {
        return $state
            .map(\.uiState)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    // MARK: - Throttled Observation

    func observeThrottled<T: Equatable>(
        _ selector: Selector<AppState, T>,
        interval: DispatchQueue.SchedulerTimeType.Stride
    ) -> AnyPublisher<T, Never> {
        return $state
            .map { selector.select($0) }
            .removeDuplicates()
            .throttle(for: interval, scheduler: DispatchQueue.main, latest: true)
            .eraseToAnyPublisher()
    }

    // MARK: - Debounced Observation

    func observeDebounced<T: Equatable>(
        _ selector: Selector<AppState, T>,
        interval: DispatchQueue.SchedulerTimeType.Stride
    ) -> AnyPublisher<T, Never> {
        return $state
            .map { selector.select($0) }
            .removeDuplicates()
            .debounce(for: interval, scheduler: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    // MARK: - Conditional Observation

    func observeWhen<T: Equatable>(
        _ selector: Selector<AppState, T>,
        condition: @escaping (AppState) -> Bool
    ) -> AnyPublisher<T, Never> {
        return $state
            .filter(condition)
            .map { selector.select($0) }
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}

// MARK: - SwiftUI Integration

@propertyWrapper
struct StoreState<T>: DynamicProperty {
    @EnvironmentObject private var store: AppStore
    @State private var value: T

    private let selector: Selector<AppState, T>
    private let cancellable: AnyCancellable?

    init(_ selector: Selector<AppState, T>) where T: Equatable {
        self.selector = selector
        self._value = State(initialValue: selector.select(.initial))
        self.cancellable = nil
    }

    var wrappedValue: T {
        return value
    }

    mutating func update() {
        let newValue = selector.select(store.state)
        if !areEqual(value, newValue) {
            value = newValue
        }
    }

    private func areEqual<U: Equatable>(_ lhs: U, _ rhs: U) -> Bool {
        return lhs == rhs
    }

    private func areEqual<U>(_ lhs: U, _ rhs: U) -> Bool {
        // For non-Equatable types, always update
        return false
    }
}

// MARK: - Memory-Safe Combine Extensions

extension Publisher {
    // Safe sink that automatically tracks cancellables
    func stateSafeSink(
        receiveCompletion: @escaping (Subscribers.Completion<Failure>) -> Void = { _ in },
        receiveValue: @escaping (Output) -> Void
    ) -> AnyCancellable {
        let cancellable = sink(
            receiveCompletion: receiveCompletion,
            receiveValue: receiveValue
        )

        // Track with MemoryManager if available
        MemoryManager.shared.track(cancellable)

        return cancellable
    }


    // Store subscription with automatic cancellation
    func store<T: AnyObject>(
        in object: T,
        cancellables: inout Set<AnyCancellable>
    ) -> AnyCancellable {
        let cancellable = self.sink { _ in } receiveValue: { _ in }
        cancellable.store(in: &cancellables)
        return cancellable
    }
}

// MARK: - Performance Monitoring

struct StateObservationMetrics {
    private static var observationCounts: [String: Int] = [:]
    private static var lastUpdateTimes: [String: Date] = [:]

    static func recordObservation(for selector: String) {
        observationCounts[selector, default: 0] += 1
        lastUpdateTimes[selector] = Date()
    }

    static func getMetrics() -> [String: Any] {
        return [
            "observationCounts": observationCounts,
            "lastUpdateTimes": lastUpdateTimes
        ]
    }

    #if DEBUG
    static func printMetrics() {
        print("State Observation Metrics:")
        for (selector, count) in observationCounts {
            let lastUpdate = lastUpdateTimes[selector]?.timeIntervalSinceNow ?? 0
            print("  \(selector): \(count) observations, last update: \(abs(lastUpdate))s ago")
        }
    }
    #endif
}