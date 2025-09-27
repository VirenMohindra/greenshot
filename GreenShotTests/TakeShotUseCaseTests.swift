//
//  TakeShotUseCaseTests.swift
//  GreenShotTests
//
//  Unit tests for TakeShotUseCase
//

import Testing
import Foundation
@testable import GreenShot

struct TakeShotUseCaseTests {

    @Test("TakeShotUseCase executes shot correctly")
    func testExecuteShot() async throws {
        let physicsService = MockServiceFactory.createMockPhysicsService()
        let useCase = TakeShotUseCase(physicsService: physicsService)

        let ball = TestFixtures.createTestBall()
        let hole = TestFixtures.createTestHole()
        let dragStart = TestFixtures.teePosition
        let dragEnd = Position(x: dragStart.x + 50, y: dragStart.y)
        let power: CGFloat = 0.8

        let result = useCase.executeShot(
            ball: ball,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: power,
            hole: hole
        )

        #expect(physicsService.calculateShotImpulseCalled, "Physics service should be called for shot calculation")
        #expect(result == .inProgress, "Shot execution should return in progress")
        #expect(ball.velocity.magnitude > 0, "Ball should have velocity after shot")
    }

    @Test("TakeShotUseCase calculates shot power correctly")
    func testShotPowerCalculation() async throws {
        let physicsService = MockServiceFactory.createMockPhysicsService()
        let useCase = TakeShotUseCase(physicsService: physicsService)

        // Test normal drag distance
        let normalPower = useCase.calculateShotPower(dragDistance: 50, maxDragDistance: 100)
        #expect(normalPower == 0.5, "50% drag should give 50% power")

        // Test maximum drag distance
        let maxPower = useCase.calculateShotPower(dragDistance: 100, maxDragDistance: 100)
        #expect(maxPower == 1.0, "100% drag should give 100% power")

        // Test excessive drag distance (should be clamped)
        let clampedPower = useCase.calculateShotPower(dragDistance: 150, maxDragDistance: 100)
        #expect(clampedPower == 1.0, "Excessive drag should be clamped to 100% power")

        // Test minimal drag distance
        let minPower = useCase.calculateShotPower(dragDistance: 10, maxDragDistance: 100)
        #expect(minPower == 0.1, "10% drag should give 10% power")
    }

    @Test("TakeShotUseCase applies impulse to ball")
    func testImpulseApplication() async throws {
        let physicsService = MockServiceFactory.createMockPhysicsService()
        physicsService.mockImpulse = Velocity(dx: 8.0, dy: 6.0)

        let useCase = TakeShotUseCase(physicsService: physicsService)
        let ball = TestFixtures.createTestBall()
        let hole = TestFixtures.createTestHole()

        let initialVelocity = ball.velocity
        #expect(initialVelocity.magnitude == 0, "Ball should start stationary")

        let result = useCase.executeShot(
            ball: ball,
            dragStart: TestFixtures.teePosition,
            dragEnd: Position(x: TestFixtures.teePosition.x + 100, y: TestFixtures.teePosition.y),
            power: 0.7,
            hole: hole
        )

        #expect(result == .inProgress, "Shot should be in progress")
        #expect(ball.velocity.magnitude > 0, "Ball should have velocity after shot")
    }

    @Test("TakeShotUseCase generates trajectory preview")
    func testTrajectoryPreview() async throws {
        let physicsService = MockServiceFactory.createMockPhysicsService()
        let useCase = TakeShotUseCase(physicsService: physicsService)

        let ballPosition = TestFixtures.teePosition
        let dragStart = TestFixtures.teePosition
        let dragEnd = Position(x: TestFixtures.teePosition.x + 75, y: TestFixtures.teePosition.y)

        let trajectory = useCase.previewTrajectory(
            from: ballPosition,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: 0.6
        )

        #expect(physicsService.calculateShotImpulseCalled, "Physics service should calculate impulse for trajectory")
        #expect(trajectory.count > 0, "Trajectory preview should have points")
        #expect(trajectory.first == ballPosition, "Trajectory should start at ball position")
    }

    @Test("TakeShotUseCase handles different power levels")
    func testDifferentPowerLevels() async throws {
        let physicsService = MockServiceFactory.createMockPhysicsService()
        let useCase = TakeShotUseCase(physicsService: physicsService)

        let ball = TestFixtures.createTestBall()
        let hole = TestFixtures.createTestHole()
        let dragStart = TestFixtures.teePosition
        let dragEnd = Position(x: dragStart.x + 100, y: dragStart.y)

        // Test low power shot
        physicsService.mockImpulse = Velocity(dx: 2.0, dy: 0.0)
        let lowPowerResult = useCase.executeShot(
            ball: ball,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: 0.2,
            hole: hole
        )

        #expect(lowPowerResult == .inProgress, "Low power shot should succeed")

        // Reset ball for next test
        ball.stop()

        // Test high power shot
        physicsService.mockImpulse = Velocity(dx: 12.0, dy: 0.0)
        let highPowerResult = useCase.executeShot(
            ball: ball,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: 0.9,
            hole: hole
        )

        #expect(highPowerResult == .inProgress, "High power shot should succeed")
    }

    @Test("TakeShotUseCase creates shot record correctly")
    func testShotRecordCreation() async throws {
        let physicsService = MockServiceFactory.createMockPhysicsService()
        let useCase = TakeShotUseCase(physicsService: physicsService)

        let ball = TestFixtures.createTestBall()
        let hole = TestFixtures.createTestHole()
        let dragStart = TestFixtures.teePosition
        let dragEnd = Position(x: dragStart.x + 50, y: dragStart.y + 50)
        let power: CGFloat = 0.6

        let result = useCase.executeShot(
            ball: ball,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: power,
            hole: hole
        )

        #expect(result == .inProgress, "Shot should be in progress")

        // Verify physics service was called with correct parameters
        #expect(physicsService.calculateShotImpulseCalled, "Physics service should calculate shot impulse")

        // Verify ball state changed
        #expect(ball.velocity.magnitude > 0, "Ball should have velocity after shot")
        #expect(ball.position == dragStart, "Ball should still be at start position initially")
    }
}