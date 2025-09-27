//
//  Constants.swift
//  GreenShot
//
//  Central repository for all magic numbers and constants used throughout the golf game
//

import Foundation
import CoreGraphics
import UIKit

struct Constants {

    // MARK: - Ball Physics
    struct Ball {
        static let radius: CGFloat = 8.0                // Visual ball radius
        static let mass: Float = 0.15                   // Ball mass in kg for realistic physics
        static let restitution: Float = 0.2             // Bounce factor (less bouncy)
        static let linearDamping: Float = 2.5           // Stopping friction
        static let angularDamping: Float = 1.2          // Spin damping
        static let friction: Float = 0.6                // Surface friction
        static let controlRadius: CGFloat = 80.0        // Touch control area radius
        static let stationaryThreshold: CGFloat = 0.1   // Speed below which ball is considered stopped
    }

    // MARK: - Physics Simulation
    struct Physics {
        static let gravity: Float = -9.81               // Earth gravity (m/s²)
        static let maxShotVelocity: Float = 15.0        // Maximum shot power
        static let velocityMultiplier: Float = 0.01     // Conversion from drag distance to velocity
        static let collisionRestitution: Float = 0.6    // Tree collision bounce factor
        static let holeDampingRadius: CGFloat = 45.0    // Hole dampening area size
        static let holeDampingFactor: Float = 0.3       // How much hole area slows ball
    }

    // MARK: - Course Generation
    struct Course {
        static let fairwayMinWidth: CGFloat = 70.0      // Minimum fairway width
        static let fairwayMaxWidth: CGFloat = 100.0     // Maximum fairway width
        static let greenRadius: CGFloat = 45.0          // Size of putting green
        static let bezierCurveSteps: Int = 20           // Smoothness of curved fairways
        static let minTreesPerHole: Int = 8             // Minimum obstacle trees
        static let maxTreesPerHole: Int = 20            // Maximum obstacle trees

        // Golf distances in yards (converted to points at 1 yard = 1 point)
        struct Distances {
            static let par3Min: Float = 100.0
            static let par3Max: Float = 250.0
            static let par4Min: Float = 250.0
            static let par4Max: Float = 450.0
            static let par5Min: Float = 450.0
            static let par5Max: Float = 550.0
        }

        // Obstacle sizing and placement
        struct Obstacles {
            // Bunker sizes
            static let bunkerMinWidth: CGFloat = 60.0       // Minimum bunker width
            static let bunkerMaxWidth: CGFloat = 120.0      // Maximum bunker width
            static let bunkerMinHeight: CGFloat = 40.0      // Minimum bunker height
            static let bunkerMaxHeight: CGFloat = 80.0      // Maximum bunker height

            // Bunker placement distances
            static let greenSideBunkerDistance: CGFloat = 60.0  // Distance from green center
            static let fairwayBunkerMinDistance: CGFloat = 180.0 // Min distance from tee for fairway bunkers
            static let fairwayBunkerMaxDistance: CGFloat = 280.0 // Max distance from tee for fairway bunkers

            // Tree sizing and types
            static let treeMinSize: CGFloat = 20.0          // Minimum tree size
            static let treeMaxSize: CGFloat = 40.0          // Maximum tree size
            static let treeHeightVariation: CGFloat = 0.3   // Height variation (±30%)
        }
    }

    // MARK: - UI Dimensions
    struct UI {
        static let buttonSize: CGFloat = 36.0           // Standard button size
        static let largeButtonSize: CGFloat = 44.0      // Large button size
        static let buttonSpacing: CGFloat = 8.0         // Spacing between buttons
        static let cornerRadius: CGFloat = 10.0         // Standard corner radius
        static let shadowRadius: CGFloat = 3.0          // Button shadow radius
        static let borderWidth: CGFloat = 1.0           // Standard border width

        struct Padding {
            static let small: CGFloat = 8.0
            static let medium: CGFloat = 16.0
            static let large: CGFloat = 20.0
            static let extraLarge: CGFloat = 24.0
        }
    }

    // MARK: - Colors (as RGB values)
    struct Colors {
        struct Golf {
            static let fairwayGreen = (red: 0.13, green: 0.37, blue: 0.15)
            static let goldenYellow = (red: 1.0, green: 0.8, blue: 0.0)
        }

        struct Ball {
            static let white = (red: 0.98, green: 0.98, blue: 0.98)
            static let dimple = (red: 0.90, green: 0.90, blue: 0.90)
            static let stroke = (red: 0.85, green: 0.85, blue: 0.85)
        }

        struct UI {
            static let buttonBackgroundAlpha: Double = 0.7
            static let buttonBorderAlpha: Double = 0.3
            static let shadowOpacityAlpha: Double = 0.3
            static let controlRadiusAlpha: Double = 0.2
        }
    }

    // MARK: - Animation
    struct Animation {
        static let ballFadeInDuration: TimeInterval = 0.3
        static let ballScaleDuration: TimeInterval = 0.1
        static let trailFadeDuration: TimeInterval = 2.0
        static let buttonPulseDuration: TimeInterval = 0.5
        static let celebrationDuration: TimeInterval = 1.0
    }

    // MARK: - Gameplay
    struct Scoring {
        static let holesPerRound: Int = 9               // 9-hole course
        static let maxStrokesPerHole: Int = 12          // Reasonable stroke limit
        static let eagleThreshold: Int = -2             // Score relative to par
        static let birdieThreshold: Int = -1
        static let bogeyThreshold: Int = 1
        static let doubleBogeyThreshold: Int = 2
    }

    // MARK: - Trail System
    struct Trail {
        static let maxPositions: Int = 30               // Maximum trail points to track
        static let dotSpacing: Int = 3                  // Show dot every N positions
        static let dotRadius: CGFloat = 1.5             // Trail dot size
        static let lineWidth: CGFloat = 2.0             // Trail line thickness
    }

    // MARK: - Camera
    struct Camera {
        static let defaultZoom: CGFloat = 0.6           // Default camera zoom level
        static let followUpdateInterval: TimeInterval = 0.1  // Camera follow frequency
        static let smoothingFactor: Float = 0.1         // Camera movement smoothing
    }

    // MARK: - Performance Settings
    struct Performance {
        // Trail system optimizations
        static let maxTrailPositions: Int = 15          // Reduced from 30
        static let trailUpdateFPS: Double = 30.0        // Down from 60fps

        // Camera update optimizations
        static let cameraUpdateFPS: Double = 20.0       // Down from 60fps

        // Rendering optimizations
        static let maxCelebrationParticles: Int = 8     // Reduced from 20+
        static let particlePoolSize: Int = 20           // Reusable particle pool

        // Texture optimizations
        static let fairwayTextureSpacing: CGFloat = 16.0    // Increased from 8
        static let textureSampleSpacing: CGFloat = 8.0      // Increased from 4

        // Tree rendering optimizations
        static let maxTreeLayers: Int = 2               // Reduced from 3-4
        static let maxPalmFronds: Int = 4               // Reduced from 8

        // Course element thresholds
        static let minFairwayTextureSize: CGFloat = 50.0    // Skip texture for small fairways
    }
}

// MARK: - Convenience Extensions
extension Constants.Colors.Golf {
    static var fairwayGreenColor: UIColor {
        UIColor(red: fairwayGreen.red, green: fairwayGreen.green, blue: fairwayGreen.blue, alpha: 1.0)
    }

    static var goldenYellowColor: UIColor {
        UIColor(red: goldenYellow.red, green: goldenYellow.green, blue: goldenYellow.blue, alpha: 1.0)
    }
}

extension Constants.Colors.Ball {
    static var whiteColor: UIColor {
        UIColor(red: white.red, green: white.green, blue: white.blue, alpha: 1.0)
    }

    static var dimpleColor: UIColor {
        UIColor(red: dimple.red, green: dimple.green, blue: dimple.blue, alpha: 0.6)
    }

    static var strokeColor: UIColor {
        UIColor(red: stroke.red, green: stroke.green, blue: stroke.blue, alpha: 1.0)
    }
}