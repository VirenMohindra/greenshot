//
//  PhysicsService.swift
//  runner
//
//  Domain service for golf ball physics calculations and rules
//

import Foundation
import CoreGraphics

protocol PhysicsServiceProtocol {
    func calculateShotImpulse(from dragStart: Position, to dragEnd: Position, power: CGFloat) -> Velocity
    func simulateTrajectory(from position: Position, with velocity: Velocity, timeStep: CGFloat, maxSteps: Int) -> [Position]
    func applyDamping(to velocity: Velocity, damping: CGFloat) -> Velocity
    func isColliding(ballPosition: Position, ballRadius: CGFloat, obstacle: Obstacle) -> Bool
    func calculateCollisionResponse(ballVelocity: Velocity, obstacle: Obstacle) -> Velocity
    func isBallStationary(_ velocity: Velocity) -> Bool
}

class PhysicsService: PhysicsServiceProtocol {

    // MARK: - Shot Mechanics
    func calculateShotImpulse(from dragStart: Position, to dragEnd: Position, power: CGFloat) -> Velocity {
        let dx = dragStart.x - dragEnd.x
        let dy = dragStart.y - dragEnd.y

        let dragDistance = sqrt(dx * dx + dy * dy)
        let maxDragDistance: CGFloat = 100
        let normalizedPower = min(dragDistance / maxDragDistance, 1.0) * power

        let maxImpulse: CGFloat = 0.3
        let impulseMultiplier = maxImpulse * normalizedPower

        return Velocity(
            dx: dx * impulseMultiplier,
            dy: dy * impulseMultiplier
        ).limited(to: Velocity.maxGolfBallSpeed)
    }

    // MARK: - Trajectory Simulation
    func simulateTrajectory(
        from position: Position,
        with velocity: Velocity,
        timeStep: CGFloat = 0.1,
        maxSteps: Int = 15
    ) -> [Position] {
        var positions: [Position] = []
        var currentPosition = position
        var currentVelocity = velocity
        let damping: CGFloat = 0.85

        for _ in 0..<maxSteps {
            positions.append(currentPosition)

            // Update position
            currentPosition = currentPosition.offset(
                by: currentVelocity.dx * timeStep,
                dy: currentVelocity.dy * timeStep
            )

            // Apply damping
            currentVelocity = currentVelocity.withDamping(damping)

            // Stop if velocity is very low
            if currentVelocity.magnitude < 0.01 {
                break
            }
        }

        return positions
    }

    // MARK: - Physics Calculations
    func applyDamping(to velocity: Velocity, damping: CGFloat) -> Velocity {
        velocity.withDamping(damping)
    }

    func isBallStationary(_ velocity: Velocity) -> Bool {
        velocity.isStationary
    }

    // MARK: - Collision Detection
    func isColliding(ballPosition: Position, ballRadius: CGFloat, obstacle: Obstacle) -> Bool {
        switch obstacle.type {
        case .tree:
            // Circular collision for trees
            let distance = ballPosition.distance(to: obstacle.position)
            return distance <= (ballRadius + obstacle.size.width / 2)

        case .water, .bunker, .rough:
            // Rectangular collision for area obstacles
            let expanded = CGRect(
                x: obstacle.bounds.origin.x - ballRadius,
                y: obstacle.bounds.origin.y - ballRadius,
                width: obstacle.bounds.width + ballRadius * 2,
                height: obstacle.bounds.height + ballRadius * 2
            )
            return expanded.contains(ballPosition.cgPoint)
        }
    }

    // MARK: - Collision Response
    func calculateCollisionResponse(ballVelocity: Velocity, obstacle: Obstacle) -> Velocity {
        switch obstacle.type {
        case .tree:
            // Elastic collision with restitution
            return ballVelocity.scaled(by: -obstacle.restitution)

        case .bunker, .rough:
            // Damped velocity for friction
            return ballVelocity.scaled(by: obstacle.damping)

        case .water:
            // Stop the ball completely
            return .zero
        }
    }
}

// MARK: - Physics Constants
extension PhysicsService {
    enum Constants {
        static let golfBallMass: CGFloat = 0.045 // kg
        static let golfBallRadius: CGFloat = 8.0 // points
        static let defaultRestitution: CGFloat = 0.3
        static let defaultFriction: CGFloat = 0.4
        static let defaultLinearDamping: CGFloat = 1.5
        static let defaultAngularDamping: CGFloat = 0.8
        static let maxBallSpeed: CGFloat = 200.0
    }
}