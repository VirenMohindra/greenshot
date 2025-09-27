//
//  ServiceContainer.swift
//  runner
//
//  Centralized dependency injection container for the golf game
//  Provides protocol-based service registration and lifecycle management
//

import Foundation
import UIKit
import SwiftUI

protocol ServiceContainerProtocol {
    func register<T>(_ serviceType: T.Type, factory: @escaping () -> T)
    func register<T>(_ serviceType: T.Type, scope: ServiceScope, factory: @escaping () -> T)
    func resolve<T>(_ serviceType: T.Type) -> T
    func resolve<T>(_ serviceType: T.Type) -> T?
}

enum ServiceScope {
    case singleton  // Single instance for app lifetime
    case transient  // New instance every time
    case scoped     // Single instance per game session
}

class ServiceContainer: ServiceContainerProtocol {
    static let shared = ServiceContainer()

    private var factories: [String: () -> Any] = [:]
    private var singletons: [String: Any] = [:]
    private var scopedInstances: [String: Any] = [:]
    private var scopes: [String: ServiceScope] = [:]

    private init() {}

    // MARK: - Registration

    func register<T>(_ serviceType: T.Type, factory: @escaping () -> T) {
        register(serviceType, scope: .singleton, factory: factory)
    }

    func register<T>(_ serviceType: T.Type, scope: ServiceScope, factory: @escaping () -> T) {
        let key = String(describing: serviceType)
        factories[key] = factory
        scopes[key] = scope
    }

    // MARK: - Resolution

    func resolve<T>(_ serviceType: T.Type) -> T {
        guard let instance: T = resolve(serviceType) else {
            fatalError("Service \(serviceType) not registered")
        }
        return instance
    }

    func resolve<T>(_ serviceType: T.Type) -> T? {
        let key = String(describing: serviceType)
        let scope = scopes[key] ?? .singleton

        switch scope {
        case .singleton:
            if let existing = singletons[key] as? T {
                return existing
            }
            guard let factory = factories[key] else { return nil }
            guard let instance = factory() as? T else {
                fatalError("Factory for \\(serviceType) returned incorrect type")
            }
            singletons[key] = instance
            return instance

        case .scoped:
            if let existing = scopedInstances[key] as? T {
                return existing
            }
            guard let factory = factories[key] else { return nil }
            guard let instance = factory() as? T else {
                fatalError("Factory for \\(serviceType) returned incorrect type")
            }
            scopedInstances[key] = instance
            return instance

        case .transient:
            guard let factory = factories[key] else { return nil }
            guard let instance = factory() as? T else {
                fatalError("Factory for \\(serviceType) returned incorrect type")
            }
            return instance
        }
    }

    // MARK: - Lifecycle Management

    func clearScopedInstances() {
        scopedInstances.removeAll()
    }

    func clearAllCaches() {
        singletons.removeAll()
        scopedInstances.removeAll()
    }
}

// MARK: - Configuration Protocol

protocol ServiceConfiguration {
    func configure(container: ServiceContainerProtocol)
}

class DefaultServiceConfiguration: ServiceConfiguration {
    func configure(container: ServiceContainerProtocol) {
        // Register configuration first (needed by other services)
        registerConfiguration(container)

        // Register core services with appropriate scopes
        registerDomainServices(container)
        registerApplicationServices(container)
        registerInfrastructureServices(container)
        registerPresentationServices(container)
    }

    private func registerConfiguration(_ container: ServiceContainerProtocol) {
        container.register(ConfigurationProtocol.self, scope: .singleton) {
            AppConfiguration.shared
        }
    }

    private func registerDomainServices(_ container: ServiceContainerProtocol) {
        container.register(PhysicsServiceProtocol.self, scope: .singleton) {
            PhysicsService()
        }

        container.register(ScoringServiceProtocol.self, scope: .singleton) {
            ScoringService()
        }

        container.register(HoleGenerationServiceProtocol.self, scope: .singleton) {
            HoleGenerationService(scoringService: container.resolve(ScoringServiceProtocol.self))
        }
    }

    private func registerApplicationServices(_ container: ServiceContainerProtocol) {
        container.register(TakeShotUseCaseProtocol.self, scope: .singleton) {
            TakeShotUseCase(physicsService: container.resolve(PhysicsServiceProtocol.self))
        }

        container.register(CompleteHoleUseCaseProtocol.self, scope: .singleton) {
            CompleteHoleUseCase(scoringService: container.resolve(ScoringServiceProtocol.self))
        }

        container.register(NavigateHolesUseCaseProtocol.self, scope: .singleton) {
            NavigateHolesUseCase()
        }

        container.register(UpdateCameraUseCaseProtocol.self, scope: .singleton) {
            UpdateCameraUseCase()
        }

        container.register(GameController.self, scope: .scoped) {
            GameController(
                takeShotUseCase: container.resolve(TakeShotUseCaseProtocol.self),
                completeHoleUseCase: container.resolve(CompleteHoleUseCaseProtocol.self),
                navigateHolesUseCase: container.resolve(NavigateHolesUseCaseProtocol.self),
                updateCameraUseCase: container.resolve(UpdateCameraUseCaseProtocol.self),
                holeGenerationService: container.resolve(HoleGenerationServiceProtocol.self),
                gameCenterService: container.resolve(GameCenterServiceProtocol.self),
                persistenceService: container.resolve(PersistenceServiceProtocol.self),
                eventBus: container.resolve(EventBusProtocol.self)
            )
        }

        container.register(CameraController.self, scope: .scoped) {
            CameraController(
                initialPosition: Position(x: 400, y: 800),
                courseSize: CGSize(width: 800, height: 1600),
                screenSize: UIScreen.main.bounds.size
            )
        }

        container.register(InputController.self, scope: .singleton) {
            InputController()
        }

        container.register(SettingsController.self, scope: .singleton) {
            SettingsController(persistenceService: container.resolve(PersistenceServiceProtocol.self))
        }

        container.register(GameCenterManager.self, scope: .singleton) {
            GameCenterManager(
                gameCenterService: container.resolve(GameCenterServiceProtocol.self),
                persistenceService: container.resolve(PersistenceServiceProtocol.self),
                eventBus: container.resolve(EventBusProtocol.self)
            )
        }
    }

    private func registerInfrastructureServices(_ container: ServiceContainerProtocol) {
        container.register(PhysicsWorldProtocol.self, scope: .singleton) {
            PhysicsWorld()
        }

        container.register(CollisionHandler.self, scope: .singleton) {
            CollisionHandler(physicsService: container.resolve(PhysicsServiceProtocol.self))
        }

        container.register(TouchInputHandler.self, scope: .singleton) {
            TouchInputHandler()
        }

        // MARK: - Persistence Services
        container.register(PersistenceServiceProtocol.self, scope: .singleton) {
            let config: ConfigurationProtocol = container.resolve(ConfigurationProtocol.self)
            if config.environment.isDebug {
                return MockPersistenceService()
            } else {
                // In production, we'd need to set up SwiftData ModelContainer
                // For now, return mock to avoid setup complexity
                return MockPersistenceService()
            }
        }

        container.register(GameCenterServiceProtocol.self, scope: .singleton) {
            let config: ConfigurationProtocol = container.resolve(ConfigurationProtocol.self)

            // Use real GameCenter in staging/production, mock in development
            if config.environment == .development {
                return MockGameCenterService()
            } else {
                // Return mock for now to avoid MainActor initialization issues
                // In production, this would be properly initialized on MainActor
                return MockGameCenterService()
            }
        }

        container.register(EventBusProtocol.self, scope: .singleton) {
            EventBus.shared
        }

        container.register(ReactiveEventBus.self, scope: .singleton) {
            // Create ReactiveEventBus without eventBus parameter for now
            // Will be initialized properly when resolved on MainActor
            ReactiveEventBus()
        }

        container.register(NetworkClientProtocol.self, scope: .singleton) {
            // Use configuration to determine base URL
            let config: ConfigurationProtocol = container.resolve(ConfigurationProtocol.self)
            let baseURL = URL(string: config.networkConfiguration.baseURL) ?? URL(string: "https://api.golfgame.com")!
            return NetworkClient(baseURL: baseURL)
        }

        container.register(NetworkServiceProtocol.self, scope: .singleton) {
            // For development, use mock service. In production, use real service.
            let config: ConfigurationProtocol = container.resolve(ConfigurationProtocol.self)
            if config.environment.isDebug {
                return MockNetworkService()
            } else {
                let networkClient: NetworkClientProtocol = container.resolve(NetworkClientProtocol.self)
                return NetworkService(networkClient: networkClient)
            }
        }

        container.register(NetworkManagerProtocol.self, scope: .singleton) {
            let networkService: NetworkServiceProtocol = container.resolve(NetworkServiceProtocol.self)
            let eventBus: EventBusProtocol = container.resolve(EventBusProtocol.self)
            return NetworkManager(networkService: networkService, eventBus: eventBus)
        }

        container.register(CourseRendererProtocol.self, scope: .singleton) {
            CourseRenderer(courseWorldSize: CGSize(width: 800, height: 1600))
        }

        container.register(BallRendererProtocol.self, scope: .singleton) {
            BallRenderer()
        }

        container.register(UIRendererProtocol.self, scope: .singleton) {
            UIRenderer(scoringService: container.resolve(ScoringServiceProtocol.self))
        }

        container.register(EffectsRendererProtocol.self, scope: .singleton) {
            EffectsRenderer()
        }
    }

    private func registerPresentationServices(_ container: ServiceContainerProtocol) {
        // View models and presentation services would be registered here
        // Currently keeping them instantiated directly in views for SwiftUI compatibility
    }
}

// MARK: - Legacy DependencyContainer Bridge

class DependencyContainer {
    private let container = ServiceContainer.shared

    init() {
        // Configure services if not already configured
        if container.resolve(PhysicsServiceProtocol.self) == nil {
            DefaultServiceConfiguration().configure(container: container)
        }
    }

    // MARK: - Computed Properties for Legacy Compatibility

    lazy var physicsService: PhysicsServiceProtocol = container.resolve(PhysicsServiceProtocol.self)
    lazy var scoringService: ScoringServiceProtocol = container.resolve(ScoringServiceProtocol.self)
    lazy var holeGenerationService: HoleGenerationServiceProtocol = container.resolve(HoleGenerationServiceProtocol.self)

    lazy var takeShotUseCase: TakeShotUseCaseProtocol = container.resolve(TakeShotUseCaseProtocol.self)
    lazy var completeHoleUseCase: CompleteHoleUseCaseProtocol = container.resolve(CompleteHoleUseCaseProtocol.self)
    lazy var navigateHolesUseCase: NavigateHolesUseCaseProtocol = container.resolve(NavigateHolesUseCaseProtocol.self)
    lazy var updateCameraUseCase: UpdateCameraUseCaseProtocol = container.resolve(UpdateCameraUseCaseProtocol.self)

    lazy var gameController: GameController = container.resolve(GameController.self)
    lazy var inputController: InputController = container.resolve(InputController.self)
    lazy var cameraController: CameraController = container.resolve(CameraController.self)
    lazy var settingsController: SettingsController = container.resolve(SettingsController.self)
    lazy var gameCenterManager: GameCenterManager = container.resolve(GameCenterManager.self)

    lazy var physicsWorld: PhysicsWorldProtocol = container.resolve(PhysicsWorldProtocol.self)
    lazy var collisionHandler: CollisionHandler = container.resolve(CollisionHandler.self)
    lazy var touchInputHandler: TouchInputHandler = container.resolve(TouchInputHandler.self)

    lazy var courseRenderer: CourseRendererProtocol = container.resolve(CourseRendererProtocol.self)
    lazy var ballRenderer: BallRendererProtocol = container.resolve(BallRendererProtocol.self)
    lazy var uiRenderer: UIRendererProtocol = container.resolve(UIRendererProtocol.self)
    lazy var effectsRenderer: EffectsRendererProtocol = container.resolve(EffectsRendererProtocol.self)
    lazy var gameCenterService: GameCenterServiceProtocol = container.resolve(GameCenterServiceProtocol.self)
    lazy var eventBus: EventBusProtocol = container.resolve(EventBusProtocol.self)
    lazy var reactiveEventBus: ReactiveEventBus = container.resolve(ReactiveEventBus.self)
    lazy var networkService: NetworkServiceProtocol = container.resolve(NetworkServiceProtocol.self)
    lazy var networkManager: NetworkManagerProtocol = container.resolve(NetworkManagerProtocol.self)
    lazy var persistenceService: PersistenceServiceProtocol = container.resolve(PersistenceServiceProtocol.self)
}