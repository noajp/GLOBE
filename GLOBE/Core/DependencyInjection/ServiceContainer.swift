//======================================================================
// MARK: - ServiceContainer.swift
// Purpose: Dependency injection container for service management
// Path: GLOBE/Core/DependencyInjection/ServiceContainer.swift
//======================================================================

import Foundation

protocol ServiceContainerProtocol {
    func register<T>(_ service: T, for type: T.Type)
    func resolve<T>(_ type: T.Type) -> T?
}

class ServiceContainer: ServiceContainerProtocol {
    static let shared = ServiceContainer()

    private var services: [String: Any] = [:]

    private init() {}

    func register<T>(_ service: T, for type: T.Type) {
        let key = String(describing: type)
        services[key] = service
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)
        return services[key] as? T
    }

    // MARK: - Convenience Methods
    func registerSingleton<T>(_ serviceFactory: @escaping () -> T, for type: T.Type) {
        let key = String(describing: type)
        if services[key] == nil {
            services[key] = serviceFactory()
        }
    }

    func reset() {
        services.removeAll()
    }
}

// MARK: - Service Locator Pattern
class ServiceLocator {
    private let container: ServiceContainerProtocol

    init(container: ServiceContainerProtocol = ServiceContainer.shared) {
        self.container = container
    }

    func authService() -> AuthServiceProtocol {
        return container.resolve(AuthServiceProtocol.self) ?? AuthManager.shared
    }

    func postService() -> PostServiceProtocol {
        return container.resolve(PostServiceProtocol.self) ?? PostManager.shared
    }

    // MARK: - Repository Access
    func userRepository() -> UserRepositoryProtocol {
        return container.resolve(UserRepositoryProtocol.self) ?? UserRepository.create()
    }

    func postRepository() -> PostRepositoryProtocol {
        return container.resolve(PostRepositoryProtocol.self) ?? PostRepository.create()
    }

    func cacheRepository() -> CacheRepositoryProtocol {
        return container.resolve(CacheRepositoryProtocol.self) ?? CacheRepository.create()
    }
}

// MARK: - Default Service Registration
extension ServiceContainer {
    func registerDefaultServices() {
        // Register repositories first
        registerSingleton({ CacheRepository.create() }, for: CacheRepositoryProtocol.self)
        registerSingleton({ UserRepository.create() }, for: UserRepositoryProtocol.self)
        registerSingleton({ PostRepository.create() }, for: PostRepositoryProtocol.self)

        // Register services that depend on repositories
        registerSingleton({ AuthManager.shared }, for: AuthServiceProtocol.self)
        registerSingleton({ PostManager.shared }, for: PostServiceProtocol.self)
    }
}

// MARK: - Global Service Access
extension ServiceContainer {
    static var serviceLocator: ServiceLocator {
        return ServiceLocator()
    }
}