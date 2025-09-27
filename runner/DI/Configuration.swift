//
//  Configuration.swift
//  runner
//
//  Runtime configuration management for the golf game
//  Handles environment-specific settings and user preferences
//

import Foundation
import CoreGraphics
import UIKit
import SwiftUI

protocol ConfigurationProtocol {
    var environment: AppEnvironment { get }
    var courseConfiguration: CourseConfiguration { get }
    var physicsConfiguration: PhysicsConfiguration { get }
    var uiConfiguration: UIConfiguration { get }
    var networkConfiguration: NetworkConfiguration { get }
    var gameConfiguration: GameConfiguration { get }
}

enum AppEnvironment {
    case development
    case staging
    case production

    var isDebug: Bool {
        switch self {
        case .development, .staging:
            return true
        case .production:
            return false
        }
    }
}

struct CourseConfiguration {
    let worldSize: CGSize
    let fairwayMinWidth: CGFloat
    let fairwayMaxWidth: CGFloat
    let greenRadius: CGFloat
    let defaultHoleCount: Int
    let maxObstaclesPerHole: Int

    static let `default` = CourseConfiguration(
        worldSize: CGSize(width: 800, height: 1600),
        fairwayMinWidth: Constants.Course.fairwayMinWidth,
        fairwayMaxWidth: Constants.Course.fairwayMaxWidth,
        greenRadius: Constants.Course.greenRadius,
        defaultHoleCount: 9,
        maxObstaclesPerHole: Constants.Course.maxTreesPerHole
    )
}

struct PhysicsConfiguration {
    let gravity: Float
    let maxShotVelocity: Float
    let ballMass: Float
    let ballRestitution: Float
    let linearDamping: Float
    let angularDamping: Float

    static let `default` = PhysicsConfiguration(
        gravity: Constants.Physics.gravity,
        maxShotVelocity: Constants.Physics.maxShotVelocity,
        ballMass: Constants.Ball.mass,
        ballRestitution: Constants.Ball.restitution,
        linearDamping: Constants.Ball.linearDamping,
        angularDamping: Constants.Ball.angularDamping
    )
}

struct UIConfiguration {
    let screenSize: CGSize
    let cameraInitialPosition: Position
    let ballControlRadius: CGFloat
    let showDebugInfo: Bool
    let enableHapticFeedback: Bool

    static func `default`() -> UIConfiguration {
        UIConfiguration(
            screenSize: UIScreen.main.bounds.size,
            cameraInitialPosition: Position(x: 400, y: 800),
            ballControlRadius: Constants.Ball.controlRadius,
            showDebugInfo: false,
            enableHapticFeedback: true
        )
    }
}

struct NetworkConfiguration {
    let baseURL: String
    let timeout: TimeInterval
    let enableRealTimeMultiplayer: Bool
    let enableGameCenter: Bool

    static let `default` = NetworkConfiguration(
        baseURL: "",  // To be configured later
        timeout: 30.0,
        enableRealTimeMultiplayer: false,
        enableGameCenter: true
    )
}

struct GameConfiguration {
    let defaultDifficulty: Float
    let enableTrajectoryPreview: Bool
    let autoZoomOnShot: Bool
    let showCelebrations: Bool
    let enableBallTrail: Bool
    let cameraSpeed: Double

    static let `default` = GameConfiguration(
        defaultDifficulty: 0.5,
        enableTrajectoryPreview: true,
        autoZoomOnShot: true,
        showCelebrations: true,
        enableBallTrail: true,
        cameraSpeed: 0.5
    )
}

class AppConfiguration: ConfigurationProtocol {
    static let shared = AppConfiguration()

    private(set) var environment: AppEnvironment
    private(set) var courseConfiguration: CourseConfiguration
    private(set) var physicsConfiguration: PhysicsConfiguration
    private(set) var uiConfiguration: UIConfiguration
    private(set) var networkConfiguration: NetworkConfiguration
    private(set) var gameConfiguration: GameConfiguration

    private init() {
        // Use EnvironmentSwitcher for intelligent environment detection
        self.environment = EnvironmentSwitcher.determineEnvironment()

        // Load default configurations
        self.courseConfiguration = .default
        self.physicsConfiguration = .default
        self.uiConfiguration = .default()
        self.networkConfiguration = .default
        self.gameConfiguration = .default

        // Override with user preferences if available
        loadUserPreferences()
    }

    // MARK: - User Preferences

    private func loadUserPreferences() {
        let defaults = UserDefaults.standard

        // Load game configuration from user preferences
        if defaults.object(forKey: "game_configuration") != nil {
            gameConfiguration = GameConfiguration(
                defaultDifficulty: Float(defaults.double(forKey: "default_difficulty")),
                enableTrajectoryPreview: defaults.bool(forKey: "enable_trajectory_preview"),
                autoZoomOnShot: defaults.bool(forKey: "auto_zoom_on_shot"),
                showCelebrations: defaults.bool(forKey: "show_celebrations"),
                enableBallTrail: defaults.bool(forKey: "enable_ball_trail"),
                cameraSpeed: defaults.double(forKey: "camera_speed")
            )
        }

        // Load UI configuration from user preferences
        uiConfiguration = UIConfiguration(
            screenSize: uiConfiguration.screenSize,
            cameraInitialPosition: uiConfiguration.cameraInitialPosition,
            ballControlRadius: uiConfiguration.ballControlRadius,
            showDebugInfo: defaults.bool(forKey: "show_debug_info"),
            enableHapticFeedback: defaults.bool(forKey: "enable_haptic_feedback")
        )
    }

    func updateGameConfiguration(_ newConfig: GameConfiguration) {
        gameConfiguration = newConfig
        saveGameConfiguration()
    }

    func updateUIConfiguration(_ newConfig: UIConfiguration) {
        uiConfiguration = newConfig
        saveUIConfiguration()
    }

    private func saveGameConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "game_configuration")
        defaults.set(gameConfiguration.defaultDifficulty, forKey: "default_difficulty")
        defaults.set(gameConfiguration.enableTrajectoryPreview, forKey: "enable_trajectory_preview")
        defaults.set(gameConfiguration.autoZoomOnShot, forKey: "auto_zoom_on_shot")
        defaults.set(gameConfiguration.showCelebrations, forKey: "show_celebrations")
        defaults.set(gameConfiguration.enableBallTrail, forKey: "enable_ball_trail")
        defaults.set(gameConfiguration.cameraSpeed, forKey: "camera_speed")
    }

    private func saveUIConfiguration() {
        let defaults = UserDefaults.standard
        defaults.set(uiConfiguration.showDebugInfo, forKey: "show_debug_info")
        defaults.set(uiConfiguration.enableHapticFeedback, forKey: "enable_haptic_feedback")
    }

    // MARK: - Environment-Specific Overrides

    func configure(for environment: AppEnvironment) {
        self.environment = environment

        switch environment {
        case .development:
            configureDevelopment()
        case .staging:
            configureStaging()
        case .production:
            configureProduction()
        }
    }

    private func configureDevelopment() {
        uiConfiguration = UIConfiguration(
            screenSize: uiConfiguration.screenSize,
            cameraInitialPosition: uiConfiguration.cameraInitialPosition,
            ballControlRadius: uiConfiguration.ballControlRadius,
            showDebugInfo: true,  // Enable debug info in development
            enableHapticFeedback: uiConfiguration.enableHapticFeedback
        )

        networkConfiguration = NetworkConfiguration(
            baseURL: "https://api-dev.golfgame.com",
            timeout: 30.0,
            enableRealTimeMultiplayer: true,
            enableGameCenter: true
        )
    }

    private func configureStaging() {
        networkConfiguration = NetworkConfiguration(
            baseURL: "https://api-staging.golfgame.com",
            timeout: 30.0,
            enableRealTimeMultiplayer: true,
            enableGameCenter: true
        )
    }

    private func configureProduction() {
        networkConfiguration = NetworkConfiguration(
            baseURL: "https://api.golfgame.com",
            timeout: 15.0,
            enableRealTimeMultiplayer: true,
            enableGameCenter: true
        )
    }
}

// MARK: - Configuration Access Helpers

extension ServiceContainer {
    func registerConfiguration() {
        register(ConfigurationProtocol.self, scope: .singleton) {
            AppConfiguration.shared
        }
    }
}

// MARK: - SwiftUI Environment Key for Configuration

struct ConfigurationKey: EnvironmentKey {
    static let defaultValue: ConfigurationProtocol = AppConfiguration.shared
}

extension EnvironmentValues {
    var configuration: ConfigurationProtocol {
        get { self[ConfigurationKey.self] }
        set { self[ConfigurationKey.self] = newValue }
    }
}