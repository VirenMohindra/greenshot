//
//  Shot.swift
//  GreenShot
//
//  Golf shot entity representing individual ball strikes
//

import Foundation
import CoreGraphics

class Shot {
    let id: UUID
    let holeNumber: Int
    let strokeNumber: Int
    let startPosition: Position
    private(set) var endPosition: Position?
    private(set) var trajectory: [Position] = []
    private(set) var power: CGFloat
    private(set) var direction: CGFloat
    private(set) var isComplete: Bool = false

    // Shot analysis
    private(set) var distance: CGFloat = 0
    private(set) var accuracy: ShotAccuracy = .unknown
    private(set) var result: ShotResult = .inProgress

    init(
        holeNumber: Int,
        strokeNumber: Int,
        startPosition: Position,
        power: CGFloat,
        direction: CGFloat
    ) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.strokeNumber = strokeNumber
        self.startPosition = startPosition
        self.power = power
        self.direction = direction
    }
}

// MARK: - Shot Execution
extension Shot {
    func updateTrajectory(_ positions: [Position]) {
        trajectory = positions
    }

    func addTrajectoryPoint(_ position: Position) {
        trajectory.append(position)
    }

    func complete(at endPosition: Position, result: ShotResult) {
        self.endPosition = endPosition
        self.result = result
        self.isComplete = true
        self.distance = startPosition.distance(to: endPosition)
        calculateAccuracy()
    }

    private func calculateAccuracy() {
        // This would be enhanced with target position for proper accuracy calculation
        accuracy = .good // Placeholder
    }
}

// MARK: - Shot Analysis
extension Shot {
    var initialVelocity: Velocity {
        let impulse = power * 0.3 // Convert power to impulse
        return Velocity(
            dx: cos(direction) * impulse,
            dy: sin(direction) * impulse
        )
    }

    var maxHeight: CGFloat {
        // Simple trajectory calculation - would be enhanced for realistic physics
        return power * 0.1
    }

    var flightTime: TimeInterval {
        // Estimate based on distance and power
        return Double(distance / max(power * 10, 1))
    }
}

// MARK: - Shot Types
enum ShotAccuracy {
    case excellent
    case good
    case fair
    case poor
    case unknown

    var description: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .fair: return "Fair"
        case .poor: return "Poor"
        case .unknown: return "Unknown"
        }
    }
}

enum ShotResult: Equatable {
    case inProgress
    case landed
    case holeIn
    case waterHazard
    case bunker
    case outOfBounds
    case hitObstacle(obstacleType: String)

    var isSuccessful: Bool {
        switch self {
        case .landed, .holeIn:
            return true
        case .inProgress, .waterHazard, .bunker, .outOfBounds, .hitObstacle:
            return false
        }
    }

    var description: String {
        switch self {
        case .inProgress: return "In progress"
        case .landed: return "Landed"
        case .holeIn: return "Hole in!"
        case .waterHazard: return "Water hazard"
        case .bunker: return "Bunker"
        case .outOfBounds: return "Out of bounds"
        case .hitObstacle(let type): return "Hit \(type)"
        }
    }
}

// MARK: - Shot Statistics
extension Shot {
    var powerPercentage: CGFloat {
        min(power / 100.0, 1.0) // Assuming max power of 100
    }

    var directionDegrees: CGFloat {
        direction * 180 / .pi
    }

    var wasSuccessful: Bool {
        result.isSuccessful
    }
}