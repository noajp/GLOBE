//======================================================================
// MARK: - Reducers.swift
// Purpose: Redux-like reducers for state management
// Path: GLOBE/Core/State/Reducers.swift
//======================================================================

import Foundation

// MARK: - Reducer Protocol

protocol Reducer {
    associatedtype State
    associatedtype Action

    func reduce(state: State, action: Action) -> State
}

// MARK: - Main App Reducer

struct AppReducer {
    static func reduce(state: AppState, action: Action) -> AppState {
        var newState = state

        // Handle actions that affect multiple state slices
        switch action {
        case let authAction as AuthAction:
            newState.authState = AuthStateReducer.reduce(state: state.authState, action: authAction)

            // Handle side effects on other states
            switch authAction {
            case .signOut:
                newState.userState = UserState.initial
                newState.postsState = PostsState.initial
                newState.uiState.showingAuth = true
            case .signInSuccess, .signUpSuccess:
                newState.uiState.showingAuth = false
            default:
                break
            }

        case let postsAction as PostsAction:
            newState.postsState = PostsStateReducer.reduce(state: state.postsState, action: postsAction)

            // Update map visible posts when posts change
            switch postsAction {
            case .fetchPostsSuccess(let posts), .fetchUserPostsSuccess(let posts):
                newState.mapState.visiblePosts = filterPostsForMap(posts: posts, zoomLevel: state.mapState.zoomLevel)
            default:
                break
            }

        case let mapAction as MapAction:
            newState.mapState = MapStateReducer.reduce(state: state.mapState, action: mapAction)

        case let userAction as UserAction:
            newState.userState = UserStateReducer.reduce(state: state.userState, action: userAction)

        case let uiAction as UIAction:
            newState.uiState = UIStateReducer.reduce(state: state.uiState, action: uiAction)

        case let appAction as AppAction:
            switch appAction {
            case .resetState:
                newState = AppState.initial
            case .clearError:
                newState.authState.error = nil
                newState.postsState.error = nil
                newState.userState.error = nil
            default:
                break
            }

        default:
            // Unknown action type - log for debugging
            SecureLogger.shared.warning("Unknown action type: \(action.type)")
        }

        return newState
    }

    // MARK: - Helper Functions

    private static func filterPostsForMap(posts: [Post], zoomLevel: Double) -> [Post] {
        let globalZoomThreshold: Double = 0.5
        let localZoomThreshold: Double = 0.05

        if zoomLevel >= globalZoomThreshold {
            // Show only high-engagement posts at global zoom
            return posts.filter { $0.likeCount >= 5 || $0.commentCount >= 3 }
        } else if zoomLevel <= localZoomThreshold {
            // Show all posts at local zoom
            return posts
        } else {
            // Show moderate engagement posts at medium zoom
            return posts.filter { $0.likeCount >= 1 || $0.commentCount >= 1 }
        }
    }
}

// MARK: - Auth State Reducer

struct AuthStateReducer {
    static func reduce(state: AuthState, action: AuthAction) -> AuthState {
        var newState = state

        switch action {
        case .signInStarted, .signUpStarted:
            newState.isLoading = true
            newState.error = nil

        case .signInSuccess(let user), .signUpSuccess(let user):
            newState.isAuthenticated = true
            newState.currentUser = user
            newState.isLoading = false
            newState.error = nil
            newState.loginAttempts = 0
            newState.isLocked = false

        case .signInFailure(let error), .signUpFailure(let error):
            newState.isAuthenticated = false
            newState.currentUser = nil
            newState.isLoading = false
            newState.error = error

        case .signOut:
            newState = AuthState.initial

        case .sessionValidated(let user):
            newState.isAuthenticated = true
            newState.currentUser = user
            newState.error = nil

        case .sessionExpired:
            newState.isAuthenticated = false
            newState.currentUser = nil
            newState.error = AppError.sessionExpired

        case .incrementLoginAttempts:
            newState.loginAttempts += 1
            if newState.loginAttempts >= 5 {
                newState.isLocked = true
            }

        case .resetLoginAttempts:
            newState.loginAttempts = 0
            newState.isLocked = false

        case .lockAccount:
            newState.isLocked = true
        }

        return newState
    }
}

// MARK: - Posts State Reducer

struct PostsStateReducer {
    static func reduce(state: PostsState, action: PostsAction) -> PostsState {
        var newState = state

        switch action {
        case .fetchPostsStarted, .createPostStarted:
            newState.isLoading = true
            newState.error = nil

        case .fetchPostsSuccess(let posts):
            newState.posts = posts
            newState.isLoading = false
            newState.error = nil
            newState.lastFetchTime = Date()

        case .fetchPostsFailure(let error), .createPostFailure(let error):
            newState.isLoading = false
            newState.error = error

        case .createPostSuccess(let post):
            newState.posts.insert(post, at: 0) // Add to beginning
            newState.isLoading = false
            newState.error = nil

        case .deletePostStarted:
            newState.isLoading = true

        case .deletePostSuccess(let postId):
            newState.posts.removeAll { $0.id == postId }
            newState.userPosts.removeAll { $0.id == postId }
            if newState.selectedPost?.id == postId {
                newState.selectedPost = nil
            }
            newState.isLoading = false

        case .deletePostFailure(_, let error):
            newState.isLoading = false
            newState.error = error

        case .selectPost(let post):
            newState.selectedPost = post

        case .toggleLike(let postId, let isLiked):
            if let index = newState.posts.firstIndex(where: { $0.id == postId }) {
                newState.posts[index].isLikedByMe = isLiked
                newState.posts[index].likeCount += isLiked ? 1 : -1
            }

        case .updatePost(let post):
            if let index = newState.posts.firstIndex(where: { $0.id == post.id }) {
                newState.posts[index] = post
            }

        case .fetchUserPostsSuccess(let posts):
            newState.userPosts = posts
        }

        return newState
    }
}

// MARK: - Map State Reducer

struct MapStateReducer {
    static func reduce(state: MapState, action: MapAction) -> MapState {
        var newState = state

        switch action {
        case .updateUserLocation(let coordinate):
            newState.userLocation = coordinate

        case .updateRegion(let region):
            newState.region = region

        case .updateLocationPermission(let status):
            newState.locationPermissionStatus = status
            newState.isLocationServicesEnabled = (status == .authorizedWhenInUse || status == .authorizedAlways)

        case .startTrackingUser:
            newState.isTrackingUser = true

        case .stopTrackingUser:
            newState.isTrackingUser = false

        case .updateVisiblePosts(let posts):
            newState.visiblePosts = posts

        case .selectPost(let post):
            newState.selectedPost = post

        case .updateZoomLevel(let level):
            newState.zoomLevel = level

        case .toggleMapType:
            // Map type toggling would be handled by specific map implementation
            break
        }

        return newState
    }
}

// MARK: - User State Reducer

struct UserStateReducer {
    static func reduce(state: UserState, action: UserAction) -> UserState {
        var newState = state

        switch action {
        case .loadProfileStarted, .updateProfileStarted:
            newState.isLoading = true
            newState.error = nil

        case .loadProfileSuccess(let profile), .updateProfileSuccess(let profile):
            newState.profile = profile
            newState.isLoading = false
            newState.error = nil

        case .loadProfileFailure(let error), .updateProfileFailure(let error):
            newState.isLoading = false
            newState.error = error

        case .loadStoriesSuccess(let stories):
            newState.stories = stories

        case .clearUserData:
            newState = UserState.initial
        }

        return newState
    }
}

// MARK: - UI State Reducer

struct UIStateReducer {
    static func reduce(state: UIState, action: UIAction) -> UIState {
        var newState = state

        switch action {
        case .selectTab(let tab):
            newState.selectedTab = tab

        case .showAuth:
            newState.showingAuth = true

        case .hideAuth:
            newState.showingAuth = false

        case .showCreatePost:
            newState.showingCreatePost = true

        case .hideCreatePost:
            newState.showingCreatePost = false

        case .showProfile:
            newState.showingProfile = true

        case .hideProfile:
            newState.showingProfile = false

        case .showSettings:
            newState.showingSettings = true

        case .hideSettings:
            newState.showingSettings = false

        case .updateNetworkStatus(let isAvailable):
            newState.isNetworkAvailable = isAvailable
        }

        return newState
    }
}

// MARK: - Reducer Helpers

extension Reducer {
    func callAsFunction(state: State, action: Action) -> State {
        return reduce(state: state, action: action)
    }
}

// MARK: - State Validation After Reduction

extension AppReducer {
    static func reduceAndValidate(state: AppState, action: Action) -> AppState {
        let newState = reduce(state: state, action: action)

        #if DEBUG
        let validationIssues = newState.validate()
        if !validationIssues.isEmpty {
            SecureLogger.shared.warning("State validation issues after action \(action.type): \(validationIssues.joined(separator: ", "))")
        }
        #endif

        return newState
    }
}