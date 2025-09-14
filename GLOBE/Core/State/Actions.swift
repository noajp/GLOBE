//======================================================================
// MARK: - Actions.swift
// Purpose: Redux-like action definitions for state management
// Path: GLOBE/Core/State/Actions.swift
//======================================================================

import Foundation
import CoreLocation

// MARK: - Action Protocol

protocol Action {
    var type: String { get }
    var timestamp: Date { get }
}

// MARK: - Auth Actions

enum AuthAction: Action {
    case signInStarted
    case signInSuccess(user: AppUser)
    case signInFailure(error: AppError)
    case signUpStarted
    case signUpSuccess(user: AppUser)
    case signUpFailure(error: AppError)
    case signOut
    case sessionValidated(user: AppUser)
    case sessionExpired
    case resetLoginAttempts
    case incrementLoginAttempts
    case lockAccount

    var type: String {
        switch self {
        case .signInStarted: return "AUTH_SIGN_IN_STARTED"
        case .signInSuccess: return "AUTH_SIGN_IN_SUCCESS"
        case .signInFailure: return "AUTH_SIGN_IN_FAILURE"
        case .signUpStarted: return "AUTH_SIGN_UP_STARTED"
        case .signUpSuccess: return "AUTH_SIGN_UP_SUCCESS"
        case .signUpFailure: return "AUTH_SIGN_UP_FAILURE"
        case .signOut: return "AUTH_SIGN_OUT"
        case .sessionValidated: return "AUTH_SESSION_VALIDATED"
        case .sessionExpired: return "AUTH_SESSION_EXPIRED"
        case .resetLoginAttempts: return "AUTH_RESET_LOGIN_ATTEMPTS"
        case .incrementLoginAttempts: return "AUTH_INCREMENT_LOGIN_ATTEMPTS"
        case .lockAccount: return "AUTH_LOCK_ACCOUNT"
        }
    }

    var timestamp: Date { Date() }
}

// MARK: - Posts Actions

enum PostsAction: Action {
    case fetchPostsStarted
    case fetchPostsSuccess(posts: [Post])
    case fetchPostsFailure(error: AppError)
    case createPostStarted
    case createPostSuccess(post: Post)
    case createPostFailure(error: AppError)
    case deletePostStarted(postId: UUID)
    case deletePostSuccess(postId: UUID)
    case deletePostFailure(postId: UUID, error: AppError)
    case selectPost(post: Post?)
    case toggleLike(postId: UUID, isLiked: Bool)
    case updatePost(post: Post)
    case fetchUserPostsSuccess(posts: [Post])

    var type: String {
        switch self {
        case .fetchPostsStarted: return "POSTS_FETCH_STARTED"
        case .fetchPostsSuccess: return "POSTS_FETCH_SUCCESS"
        case .fetchPostsFailure: return "POSTS_FETCH_FAILURE"
        case .createPostStarted: return "POSTS_CREATE_STARTED"
        case .createPostSuccess: return "POSTS_CREATE_SUCCESS"
        case .createPostFailure: return "POSTS_CREATE_FAILURE"
        case .deletePostStarted: return "POSTS_DELETE_STARTED"
        case .deletePostSuccess: return "POSTS_DELETE_SUCCESS"
        case .deletePostFailure: return "POSTS_DELETE_FAILURE"
        case .selectPost: return "POSTS_SELECT_POST"
        case .toggleLike: return "POSTS_TOGGLE_LIKE"
        case .updatePost: return "POSTS_UPDATE_POST"
        case .fetchUserPostsSuccess: return "POSTS_FETCH_USER_POSTS_SUCCESS"
        }
    }

    var timestamp: Date { Date() }
}

// MARK: - Map Actions

enum MapAction: Action {
    case updateUserLocation(coordinate: CLLocationCoordinate2D)
    case updateRegion(region: MapRegion)
    case updateLocationPermission(status: LocationPermissionStatus)
    case startTrackingUser
    case stopTrackingUser
    case updateVisiblePosts(posts: [Post])
    case selectPost(post: Post?)
    case updateZoomLevel(level: Double)
    case toggleMapType

    var type: String {
        switch self {
        case .updateUserLocation: return "MAP_UPDATE_USER_LOCATION"
        case .updateRegion: return "MAP_UPDATE_REGION"
        case .updateLocationPermission: return "MAP_UPDATE_LOCATION_PERMISSION"
        case .startTrackingUser: return "MAP_START_TRACKING_USER"
        case .stopTrackingUser: return "MAP_STOP_TRACKING_USER"
        case .updateVisiblePosts: return "MAP_UPDATE_VISIBLE_POSTS"
        case .selectPost: return "MAP_SELECT_POST"
        case .updateZoomLevel: return "MAP_UPDATE_ZOOM_LEVEL"
        case .toggleMapType: return "MAP_TOGGLE_MAP_TYPE"
        }
    }

    var timestamp: Date { Date() }
}

// MARK: - User Actions

enum UserAction: Action {
    case loadProfileStarted
    case loadProfileSuccess(profile: UserProfile)
    case loadProfileFailure(error: AppError)
    case updateProfileStarted
    case updateProfileSuccess(profile: UserProfile)
    case updateProfileFailure(error: AppError)
    case loadStoriesSuccess(stories: [Story])
    case clearUserData

    var type: String {
        switch self {
        case .loadProfileStarted: return "USER_LOAD_PROFILE_STARTED"
        case .loadProfileSuccess: return "USER_LOAD_PROFILE_SUCCESS"
        case .loadProfileFailure: return "USER_LOAD_PROFILE_FAILURE"
        case .updateProfileStarted: return "USER_UPDATE_PROFILE_STARTED"
        case .updateProfileSuccess: return "USER_UPDATE_PROFILE_SUCCESS"
        case .updateProfileFailure: return "USER_UPDATE_PROFILE_FAILURE"
        case .loadStoriesSuccess: return "USER_LOAD_STORIES_SUCCESS"
        case .clearUserData: return "USER_CLEAR_DATA"
        }
    }

    var timestamp: Date { Date() }
}

// MARK: - UI Actions

enum UIAction: Action {
    case selectTab(tab: TabSelection)
    case showAuth
    case hideAuth
    case showCreatePost
    case hideCreatePost
    case showProfile
    case hideProfile
    case showSettings
    case hideSettings
    case updateNetworkStatus(isAvailable: Bool)

    var type: String {
        switch self {
        case .selectTab: return "UI_SELECT_TAB"
        case .showAuth: return "UI_SHOW_AUTH"
        case .hideAuth: return "UI_HIDE_AUTH"
        case .showCreatePost: return "UI_SHOW_CREATE_POST"
        case .hideCreatePost: return "UI_HIDE_CREATE_POST"
        case .showProfile: return "UI_SHOW_PROFILE"
        case .hideProfile: return "UI_HIDE_PROFILE"
        case .showSettings: return "UI_SHOW_SETTINGS"
        case .hideSettings: return "UI_HIDE_SETTINGS"
        case .updateNetworkStatus: return "UI_UPDATE_NETWORK_STATUS"
        }
    }

    var timestamp: Date { Date() }
}

// MARK: - Generic Actions

enum AppAction: Action {
    case resetState
    case clearError
    case updateLastActivity

    var type: String {
        switch self {
        case .resetState: return "APP_RESET_STATE"
        case .clearError: return "APP_CLEAR_ERROR"
        case .updateLastActivity: return "APP_UPDATE_LAST_ACTIVITY"
        }
    }

    var timestamp: Date { Date() }
}

// MARK: - Action Helpers

extension Action {
    func log() {
        SecureLogger.shared.info("Action dispatched - type: \(type), timestamp: \(timestamp.ISO8601Format())")
    }

    var debugDescription: String {
        "Action(type: \(type), timestamp: \(timestamp.ISO8601Format()))"
    }
}

// MARK: - Action Creator Helpers

struct ActionCreators {
    // MARK: - Auth Action Creators
    static func signIn(email: String, password: String) -> [Action] {
        return [AuthAction.signInStarted]
    }

    static func signInSuccess(user: AppUser) -> [Action] {
        return [
            AuthAction.signInSuccess(user: user),
            UIAction.hideAuth
        ]
    }

    static func signInFailure(error: AppError) -> [Action] {
        return [
            AuthAction.signInFailure(error: error),
            AuthAction.incrementLoginAttempts
        ]
    }

    static func signOut() -> [Action] {
        return [
            AuthAction.signOut,
            UserAction.clearUserData,
            UIAction.showAuth,
            UIAction.selectTab(tab: .map)
        ]
    }

    // MARK: - Posts Action Creators
    static func createPostSuccess(post: Post) -> [Action] {
        return [
            PostsAction.createPostSuccess(post: post),
            UIAction.hideCreatePost
        ]
    }

    static func deletePost(postId: UUID) -> [Action] {
        return [
            PostsAction.deletePostStarted(postId: postId)
        ]
    }

    // MARK: - UI Action Creators
    static func showCreatePost() -> [Action] {
        // Only show if authenticated
        return [UIAction.showCreatePost]
    }

    static func selectTab(_ tab: TabSelection) -> [Action] {
        return [UIAction.selectTab(tab: tab)]
    }
}