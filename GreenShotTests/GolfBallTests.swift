//
//  GolfBallTests.swift
//  GreenShotTests
//
//  Unit tests for GolfBall entity physics and state management
//

import Testing
import Foundation
@testable import GreenShot

struct GolfBallTests {

    @Test("Golf ball initializes correctly")
    func testGolfBallInitialization() async throws {
        let initialPosition = TestFixtures.teePosition
        let ball = GolfBall(position: initialPosition)

        #expect(ball.position == initialPosition, "Ball position should match initial position")
        #expect(ball.velocity == Velocity(dx: 0, dy: 0), "Ball should start with zero velocity")
        #expect(ball.isVisible == true, "Ball should be visible initially")
        #expect(ball.isStationary, "Ball should be stationary initially")
        #expect(!ball.isMoving, "Ball should not be moving initially")
    }

    @Test("Golf ball position updates correctly")
    func testPositionUpdate() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        let newPosition = TestFixtures.pinPosition

        ball.updatePosition(newPosition)

        #expect(ball.position == newPosition, "Ball position should update correctly")
    }

    @Test("Golf ball velocity updates correctly")
    func testVelocityUpdate() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        let newVelocity = Velocity(dx: 5.0, dy: 3.0)

        ball.updateVelocity(newVelocity)

        #expect(ball.velocity == newVelocity, "Ball velocity should update correctly")
        #expect(ball.isMoving, "Ball should be moving after velocity update")
        #expect(!ball.isStationary, "Ball should not be stationary after velocity update")
    }

    @Test("Golf ball visibility controls")
    func testVisibilityControls() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)

        #expect(ball.isVisible, "Ball should start visible")

        ball.hide()
        #expect(!ball.isVisible, "Ball should be hidden after hide()")

        ball.show()
        #expect(ball.isVisible, "Ball should be visible after show()")
    }

    @Test("Golf ball stop functionality")
    func testStopBall() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        ball.updateVelocity(Velocity(dx: 10.0, dy: 5.0))

        #expect(ball.isMoving, "Ball should be moving before stop")

        ball.stop()

        #expect(ball.velocity == Velocity.zero, "Ball velocity should be zero after stop")
        #expect(ball.isStationary, "Ball should be stationary after stop")
        #expect(!ball.isMoving, "Ball should not be moving after stop")
    }

    @Test("Golf ball reset functionality")
    func testResetBall() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        let resetPosition = TestFixtures.pinPosition

        // Modify ball state
        ball.updateVelocity(Velocity(dx: 10.0, dy: 5.0))
        ball.hide()

        ball.reset(to: resetPosition)

        #expect(ball.position == resetPosition, "Ball position should reset correctly")
        #expect(ball.velocity == Velocity.zero, "Ball velocity should reset to zero")
        #expect(ball.isVisible, "Ball should be visible after reset")
        #expect(ball.isStationary, "Ball should be stationary after reset")
    }

    @Test("Golf ball physics properties")
    func testPhysicsProperties() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)

        #expect(ball.mass == 0.045, "Ball mass should be standard golf ball mass")
        #expect(ball.radius == 8.0, "Ball radius should be 8 points")
        #expect(ball.restitution == 0.3, "Ball restitution should be 0.3")
        #expect(ball.friction == 0.4, "Ball friction should be 0.4")
    }

    @Test("Golf ball impulse application")
    func testApplyImpulse() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        let impulse = Velocity(dx: 5.0, dy: 3.0)

        ball.applyImpulse(impulse)

        #expect(ball.velocity.dx == impulse.dx, "Ball velocity X should match impulse")
        #expect(ball.velocity.dy == impulse.dy, "Ball velocity Y should match impulse")
        #expect(ball.isMoving, "Ball should be moving after impulse")
    }

    @Test("Golf ball impulse accumulation")
    func testMultipleImpulses() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        let impulse1 = Velocity(dx: 2.0, dy: 1.0)
        let impulse2 = Velocity(dx: 3.0, dy: 2.0)

        ball.applyImpulse(impulse1)
        ball.applyImpulse(impulse2)

        let expectedVelocity = Velocity(dx: 5.0, dy: 3.0)
        #expect(TestAssertions.assertVelocitiesEqual(ball.velocity, expectedVelocity),
                "Ball velocity should accumulate impulses")
    }

    @Test("Golf ball damping application")
    func testApplyDamping() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        ball.updateVelocity(Velocity(dx: 10.0, dy: 6.0))
        let originalSpeed = ball.speed

        ball.applyDamping(0.9)

        #expect(ball.speed < originalSpeed, "Ball speed should decrease with damping")
        #expect(ball.velocity.dx < 10.0, "Ball velocity X should decrease")
        #expect(ball.velocity.dy < 6.0, "Ball velocity Y should decrease")
    }

    @Test("Golf ball speed and direction calculations")
    func testSpeedAndDirection() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        ball.updateVelocity(Velocity(dx: 3.0, dy: 4.0))

        #expect(TestAssertions.assertCGFloatEqual(ball.speed, 5.0), "Speed should be magnitude of velocity vector")

        let expectedDirection = atan2(4.0, 3.0)
        #expect(TestAssertions.assertCGFloatEqual(ball.direction, expectedDirection),
                "Direction should be atan2(dy, dx)")
    }

    @Test("Golf ball distance calculation")
    func testDistanceCalculation() async throws {
        let ball = GolfBall(position: Position(x: 0, y: 0))
        let targetPosition = Position(x: 3, y: 4)

        let distance = ball.distanceTo(targetPosition)

        #expect(TestAssertions.assertCGFloatEqual(distance, 5.0), "Distance should be calculated correctly")
    }

    @Test("Golf ball stationary detection")
    func testStationaryDetection() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)

        #expect(ball.isStationary, "Ball should start stationary")
        #expect(!ball.isMoving, "Ball should not be moving initially")

        ball.updateVelocity(Velocity(dx: 0.01, dy: 0.01)) // Below threshold
        #expect(ball.isStationary, "Ball should be stationary with very low velocity")

        ball.updateVelocity(Velocity(dx: 1.0, dy: 0.5)) // Above threshold
        #expect(!ball.isStationary, "Ball should not be stationary with normal velocity")
        #expect(ball.isMoving, "Ball should be moving with normal velocity")
    }

    @Test("Golf ball impulse speed limiting")
    func testImpulseSpeedLimiting() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)
        let massiveImpulse = Velocity(dx: 1000.0, dy: 1000.0)

        ball.applyImpulse(massiveImpulse)

        // The ball should not exceed maximum golf ball speed
        #expect(ball.speed <= Velocity.maxGolfBallSpeed, "Ball speed should be limited to maximum")
    }

    @Test("Golf ball state consistency")
    func testStateConsistency() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)

        // Moving state consistency
        ball.updateVelocity(Velocity(dx: 5.0, dy: 0.0))
        #expect(ball.isMoving == !ball.isStationary, "Moving and stationary states should be opposite")

        // Stopping consistency
        ball.stop()
        #expect(ball.isStationary, "Ball should be stationary after stop")
        #expect(ball.speed == 0, "Ball speed should be zero after stop")

        // Reset consistency
        let newPosition = TestFixtures.pinPosition
        ball.reset(to: newPosition)
        #expect(ball.position == newPosition, "Position should match reset position")
        #expect(ball.isStationary, "Ball should be stationary after reset")
        #expect(ball.isVisible, "Ball should be visible after reset")
    }

    @Test("Golf ball physics integration")
    func testPhysicsIntegration() async throws {
        let ball = GolfBall(position: TestFixtures.teePosition)

        // Apply impulse and damping in sequence
        let initialImpulse = Velocity(dx: 10.0, dy: 0.0)
        ball.applyImpulse(initialImpulse)
        let speedAfterImpulse = ball.speed

        ball.applyDamping(0.8)
        let speedAfterDamping = ball.speed

        #expect(speedAfterDamping < speedAfterImpulse, "Damping should reduce speed")
        #expect(speedAfterDamping > 0, "Ball should still be moving after light damping")

        // Apply heavy damping to stop
        ball.applyDamping(0.01)
        #expect(ball.speed < speedAfterDamping, "Heavy damping should reduce speed further")
    }
}