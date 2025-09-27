//
//  GolfBall.swift
//  runner
//
//  Golf ball entity with position and physics state
//

import Foundation
import CoreGraphics

class GolfBall {
    private(set) var position: Position
    private(set) var velocity: Velocity
    private(set) var isVisible: Bool

    // Physics properties
    let mass: CGFloat = 0.045 // kg
    let radius: CGFloat = 8.0 // points
    let restitution: CGFloat = 0.3
    let friction: CGFloat = 0.4

    init(position: Position) {
        self.position = position
        self.velocity = .zero
        self.isVisible = true
    }
}

// MARK: - State Management
extension GolfBall {
    func updatePosition(_ newPosition: Position) {
        position = newPosition
    }

    func updateVelocity(_ newVelocity: Velocity) {
        velocity = newVelocity
    }

    func stop() {
        velocity = .zero
    }

    func hide() {
        isVisible = false
    }

    func show() {
        isVisible = true
    }

    func reset(to position: Position) {
        self.position = position
        velocity = .zero
        isVisible = true
    }
}

// MARK: - Physics State
extension GolfBall {
    var isMoving: Bool {
        !velocity.isStationary
    }

    var isStationary: Bool {
        velocity.isStationary
    }

    var speed: CGFloat {
        velocity.magnitude
    }

    var direction: CGFloat {
        velocity.direction
    }
}

// MARK: - Golf Mechanics
extension GolfBall {
    func applyImpulse(_ impulse: Velocity) {
        // Apply impulse respecting max ball speed
        let newVelocity = Velocity(
            dx: velocity.dx + impulse.dx,
            dy: velocity.dy + impulse.dy
        ).limited(to: Velocity.maxGolfBallSpeed)

        updateVelocity(newVelocity)
    }

    func applyDamping(_ damping: CGFloat) {
        updateVelocity(velocity.withDamping(damping))
    }

    func distanceTo(_ position: Position) -> CGFloat {
        self.position.distance(to: position)
    }
}