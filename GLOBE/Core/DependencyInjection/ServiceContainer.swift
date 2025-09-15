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

    func authService() -> any AuthServiceProtocol {
        return container.resolve((any AuthServiceProtocol).self) ?? AuthManager.shared
    }

    func postService() -> any PostServiceProtocol {
        return container.resolve((any PostServiceProtocol).self) ?? PostManager.shared
    }

    // MARK: - Repository Access
    func userRepository() -> any UserRepositoryProtocol {
        return container.resolve((any UserRepositoryProtocol).self) ?? UserRepository.create()
    }

    func postRepository() -> any PostRepositoryProtocol {
        return container.resolve((any PostRepositoryProtocol).self) ?? PostRepository.create()
    }

    func cacheRepository() -> any CacheRepositoryProtocol {
        return container.resolve((any CacheRepositoryProtocol).self) ?? CacheRepository.create()
    }
}

// MARK: - Default Service Registration
extension ServiceContainer {
    func registerDefaultServices() {
        // Register repositories first
        registerSingleton({ CacheRepository.create() as any CacheRepositoryProtocol }, for: (any CacheRepositoryProtocol).self)
        registerSingleton({ UserRepository.create() as any UserRepositoryProtocol }, for: (any UserRepositoryProtocol).self)
        registerSingleton({ PostRepository.create() as any PostRepositoryProtocol }, for: (any PostRepositoryProtocol).self)

        // Register services that depend on repositories
        registerSingleton({ AuthManager.shared as any AuthServiceProtocol }, for: (any AuthServiceProtocol).self)
        registerSingleton({ PostManager.shared as any PostServiceProtocol }, for: (any PostServiceProtocol).self)
    }
}

// MARK: - Global Service Access
extension ServiceContainer {
    static var serviceLocator: ServiceLocator {
        return ServiceLocator()
    }
}
