//
//  PhysicsServiceTests.swift
//  runnerTests
//
//  Unit tests for physics service calculations
//

import Testing
import Foundation
@testable import runner

struct PhysicsServiceTests {

    let physicsService = PhysicsService()

    @Test("Physics service calculates shot impulse correctly")
    func testCalculateShotImpulse() async throws {
        // Test basic impulse calculation
        let dragStart = Position(x: 100, y: 100)
        let dragEnd = Position(x: 150, y: 100)  // 50 points horizontal drag

        let impulse = physicsService.calculateShotImpulse(
            dragStart: dragStart,
            dragEnd: dragEnd
        )

        // Should scale drag distance to reasonable impulse
        #expect(impulse.dx > 0, "Horizontal impulse should be positive for rightward drag")
        #expect(impulse.dy == 0, "Vertical impulse should be zero for horizontal drag")
        #expect(impulse.magnitude <= Constants.Physics.maxShotVelocity, "Impulse should not exceed maximum velocity")
    }

    @Test("Physics service applies damping correctly")
    func testApplyDamping() async throws {
        var velocity = Velocity(dx: 10.0, dy: 5.0)
        let deltaTime: Float = 0.016 // ~60fps

        let dampedVelocity = physicsService.applyDamping(
            velocity: velocity,
            dampingFactor: Constants.Ball.linearDamping,
            deltaTime: deltaTime
        )

        // Velocity should be reduced but not negative
        #expect(dampedVelocity.dx < velocity.dx, "X velocity should be reduced")
        #expect(dampedVelocity.dy < velocity.dy, "Y velocity should be reduced")
        #expect(dampedVelocity.dx >= 0, "X velocity should not become negative")
        #expect(dampedVelocity.dy >= 0, "Y velocity should not become negative")
    }

    @Test("Physics service detects stationary ball correctly")
    func testIsStationary() async throws {
        let stationaryVelocity = Velocity(dx: 0.05, dy: 0.05) // Below threshold
        let movingVelocity = Velocity(dx: 1.0, dy: 1.0)       // Above threshold

        #expect(physicsService.isStationary(stationaryVelocity), "Should detect stationary ball")
        #expect(!physicsService.isStationary(movingVelocity), "Should detect moving ball")
    }

    @Test("Physics service calculates realistic trajectory")
    func testCalculateTrajectory() async throws {
        let initialPosition = Position(x: 0, y: 0)
        let initialVelocity = Velocity(dx: 10.0, dy: 10.0)

        let trajectory = physicsService.calculateTrajectory(
            startPosition: initialPosition,
            initialVelocity: initialVelocity,
            timeStep: 0.1,
            maxTime: 2.0
        )

        #expect(trajectory.count > 5, "Should generate reasonable number of trajectory points")
        #expect(trajectory.first?.x == initialPosition.x, "First point should match start position")
        #expect(trajectory.first?.y == initialPosition.y, "First point should match start position")

        // Ball should move forward and curve due to physics
        let lastPoint = trajectory.last!
        #expect(lastPoint.x > initialPosition.x, "Ball should move forward")
    }
}