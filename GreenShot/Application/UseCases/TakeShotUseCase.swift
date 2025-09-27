//
//  TakeShotUseCase.swift
//  runner
//
//  Use case for handling golf shot input and execution
//

import Foundation
import CoreGraphics

protocol TakeShotUseCaseProtocol {
    func executeShot(
        ball: GolfBall,
        dragStart: Position,
        dragEnd: Position,
        power: CGFloat,
        hole: Hole
    ) -> ShotResult

    func previewTrajectory(
        from position: Position,
        dragStart: Position,
        dragEnd: Position,
        power: CGFloat
    ) -> [Position]

    func calculateShotPower(dragDistance: CGFloat, maxDragDistance: CGFloat) -> CGFloat
}

class TakeShotUseCase: TakeShotUseCaseProtocol {
    private let physicsService: PhysicsServiceProtocol

    init(physicsService: PhysicsServiceProtocol) {
        self.physicsService = physicsService
    }

    func executeShot(
        ball: GolfBall,
        dragStart: Position,
        dragEnd: Position,
        power: CGFloat,
        hole: Hole
    ) -> ShotResult {
        // Calculate shot impulse
        let impulse = physicsService.calculateShotImpulse(
            from: dragStart,
            to: dragEnd,
            power: power
        )

        // Apply impulse to ball
        ball.applyImpulse(impulse)

        // Create shot record
        let shot = Shot(
            holeNumber: hole.number,
            strokeNumber: 1, // This would be managed by the game controller
            startPosition: ball.position,
            power: power,
            direction: dragStart.direction(to: dragEnd)
        )

        return ShotResult.inProgress
    }

    func previewTrajectory(
        from position: Position,
        dragStart: Position,
        dragEnd: Position,
        power: CGFloat
    ) -> [Position] {
        let velocity = physicsService.calculateShotImpulse(
            from: dragStart,
            to: dragEnd,
            power: power
        )

        return physicsService.simulateTrajectory(
            from: position,
            with: velocity,
            timeStep: 0.02, // 50 FPS simulation
            maxSteps: 300   // About 6 seconds of trajectory
        )
    }

    func calculateShotPower(dragDistance: CGFloat, maxDragDistance: CGFloat = 100.0) -> CGFloat {
        return min(dragDistance / maxDragDistance, 1.0)
    }
}

// MARK: - Shot Validation
extension TakeShotUseCase {
    private func validateShot(ball: GolfBall, hole: Hole) -> ShotValidationResult {
        guard ball.isStationary else {
            return .invalid(reason: "Ball must be stationary")
        }

        guard ball.isVisible else {
            return .invalid(reason: "Ball is not visible")
        }

        return .valid
    }
}

enum ShotValidationResult {
    case valid
    case invalid(reason: String)

    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
}