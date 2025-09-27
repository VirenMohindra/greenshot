//
//  Obstacle.swift
//  runner
//
//  Golf course obstacle entity (water, bunkers, trees, etc.)
//

import Foundation
import CoreGraphics

class Obstacle {
    let id: UUID
    let type: ObstacleType
    let position: Position
    let size: CGSize

    init(type: ObstacleType, position: Position, size: CGSize) {
        self.id = UUID()
        self.type = type
        self.position = position
        self.size = size
    }
}

// MARK: - Obstacle Types
enum ObstacleType: CaseIterable {
    case water
    case bunker
    case tree
    case rough

    var penaltyStrokes: Int {
        switch self {
        case .water: return 1
        case .bunker: return 0
        case .tree: return 0
        case .rough: return 0
        }
    }

    var affectsBallPhysics: Bool {
        switch self {
        case .water: return false // Ball stops/resets
        case .bunker: return true // High friction
        case .tree: return true // Solid collision
        case .rough: return true // Medium friction
        }
    }

    var isHazard: Bool {
        switch self {
        case .water: return true
        case .bunker: return true
        case .tree: return false
        case .rough: return false
        }
    }

    var displayName: String {
        switch self {
        case .water: return "Water Hazard"
        case .bunker: return "Sand Bunker"
        case .tree: return "Tree"
        case .rough: return "Rough"
        }
    }
}

// MARK: - Physics Properties
extension Obstacle {
    var damping: CGFloat {
        switch type {
        case .water: return 0.0 // Ball stops immediately
        case .bunker: return 0.3 // High resistance
        case .tree: return 1.0 // No damping (solid collision)
        case .rough: return 0.7 // Medium resistance
        }
    }

    var friction: CGFloat {
        switch type {
        case .water: return 0.0
        case .bunker: return 2.0
        case .tree: return 0.8
        case .rough: return 1.5
        }
    }

    var restitution: CGFloat {
        switch type {
        case .water: return 0.0
        case .bunker: return 0.1
        case .tree: return 0.6 // More bouncy for dramatic tree collisions
        case .rough: return 0.2
        }
    }
}

// MARK: - Spatial Properties
extension Obstacle {
    var bounds: CGRect {
        CGRect(
            x: position.x - size.width / 2,
            y: position.y - size.height / 2,
            width: size.width,
            height: size.height
        )
    }

    func contains(_ position: Position) -> Bool {
        bounds.contains(position.cgPoint)
    }

    func distanceTo(_ position: Position) -> CGFloat {
        self.position.distance(to: position)
    }
}

// MARK: - Game Effects
extension Obstacle {
    func applyEffect(to ball: GolfBall) -> ObstacleEffect {
        switch type {
        case .water:
            return .penalty(strokes: 1, resetToLastPosition: true)
        case .bunker:
            return .physics(damping: damping, friction: friction)
        case .tree:
            return .collision(restitution: restitution)
        case .rough:
            return .physics(damping: damping, friction: friction)
        }
    }
}

// MARK: - Obstacle Effects
enum ObstacleEffect {
    case penalty(strokes: Int, resetToLastPosition: Bool)
    case physics(damping: CGFloat, friction: CGFloat)
    case collision(restitution: CGFloat)
    case none
}