//
//  PhysicsServiceTests.swift
//  runnerTests
//
//  Unit tests for physics service calculations
//

import Testing
import Foundation
@testable import GreenShot

struct PhysicsServiceTests {

    let physicsService = PhysicsService()

    @Test("Physics service calculates shot impulse correctly")
    func testCalculateShotImpulse() async throws {
        // Test basic impulse calculation
        let dragStart = Position(x: 100, y: 100)
        let dragEnd = Position(x: 150, y: 100)  // 50 points horizontal drag
        let power: CGFloat = 1.0

        let impulse = physicsService.calculateShotImpulse(
            from: dragStart,
            to: dragEnd,
            power: power
        )

        // Should scale drag distance to reasonable impulse
        #expect(impulse.dx != 0, "Should have horizontal component for horizontal drag")
        #expect(impulse.dy == 0, "Vertical impulse should be zero for horizontal drag")
        #expect(impulse.magnitude <= Velocity.maxGolfBallSpeed, "Impulse should not exceed maximum velocity")
    }

    @Test("Physics service applies damping correctly")
    func testApplyDamping() async throws {
        let velocity = Velocity(dx: 10.0, dy: 5.0)
        let damping: CGFloat = 0.9

        let dampedVelocity = physicsService.applyDamping(
            to: velocity,
            damping: damping
        )

        // Velocity should be reduced
        #expect(dampedVelocity.magnitude < velocity.magnitude, "Velocity magnitude should be reduced")
        #expect(dampedVelocity.dx != 0, "Should still have some horizontal velocity")
        #expect(dampedVelocity.dy != 0, "Should still have some vertical velocity")
    }

    @Test("Physics service detects stationary ball correctly")
    func testIsStationary() async throws {
        let stationaryVelocity = Velocity(dx: 0.005, dy: 0.005) // Below threshold
        let movingVelocity = Velocity(dx: 1.0, dy: 1.0)       // Above threshold

        #expect(physicsService.isBallStationary(stationaryVelocity), "Should detect stationary ball")
        #expect(!physicsService.isBallStationary(movingVelocity), "Should detect moving ball")
    }

    @Test("Physics service calculates realistic trajectory")
    func testCalculateTrajectory() async throws {
        let initialPosition = Position(x: 0, y: 0)
        let initialVelocity = Velocity(dx: 10.0, dy: 10.0)

        let trajectory = physicsService.simulateTrajectory(
            from: initialPosition,
            with: initialVelocity,
            timeStep: 0.1,
            maxSteps: 20
        )

        #expect(trajectory.count > 5, "Should generate reasonable number of trajectory points")
        #expect(trajectory.first?.x == initialPosition.x, "First point should match start position")
        #expect(trajectory.first?.y == initialPosition.y, "First point should match start position")

        // Ball should move forward due to initial velocity
        let lastPoint = trajectory.last!
        #expect(lastPoint.x != initialPosition.x || lastPoint.y != initialPosition.y, "Ball should move from initial position")
    }
}