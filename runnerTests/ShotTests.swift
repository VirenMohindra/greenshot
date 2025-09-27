//
//  ShotTests.swift
//  GreenShotTests
//
//  Unit tests for Shot entity
//

import Testing
import Foundation
@testable import runner

struct ShotTests {

    @Test("Shot initializes correctly")
    func testShotInitialization() async throws {
        let shot = TestFixtures.createTestShot(power: 0.7, direction: CGFloat.pi / 4)

        #expect(shot.startPosition == TestFixtures.teePosition, "Shot should have correct start position")
        #expect(shot.power == 0.7, "Shot should have correct power")
        #expect(shot.direction == CGFloat.pi / 4, "Shot should have correct direction")
        #expect(shot.holeNumber == 1, "Shot should have correct hole number")
        #expect(shot.strokeNumber == 1, "Shot should have correct stroke number")
    }

    @Test("Shot completion and distance calculation")
    func testShotCompletion() async throws {
        let shot = TestFixtures.createTestShot()
        let endPosition = Position(x: TestFixtures.teePosition.x + 100, y: TestFixtures.teePosition.y + 50)

        #expect(!shot.isComplete, "Shot should not be complete initially")

        shot.complete(at: endPosition, result: .landed)

        #expect(shot.isComplete, "Shot should be complete after completion")
        #expect(shot.endPosition == endPosition, "Shot should have correct end position")
        #expect(shot.distance > 0, "Shot should have calculated distance")
        #expect(shot.result == .landed, "Shot should have correct result")
    }

    @Test("Shot trajectory tracking")
    func testTrajectoryTracking() async throws {
        let shot = TestFixtures.createTestShot()
        let trajectoryPoints = [
            TestFixtures.teePosition,
            Position(x: TestFixtures.teePosition.x + 50, y: TestFixtures.teePosition.y + 25),
            Position(x: TestFixtures.teePosition.x + 100, y: TestFixtures.teePosition.y + 50)
        ]

        shot.updateTrajectory(trajectoryPoints)

        #expect(shot.trajectory.count == 3, "Shot should have 3 trajectory points")
        #expect(shot.trajectory.first == TestFixtures.teePosition, "Trajectory should start at shot start position")
        #expect(shot.trajectory.last == trajectoryPoints.last, "Trajectory should end at last trajectory point")
    }

    @Test("Shot physics calculations")
    func testShotPhysicsCalculations() async throws {
        let shot = TestFixtures.createTestShot(power: 0.8, direction: CGFloat.pi / 6)

        let initialVelocity = shot.initialVelocity
        #expect(initialVelocity.magnitude > 0, "Initial velocity should have magnitude")

        let powerPercentage = shot.powerPercentage
        #expect(powerPercentage >= 0 && powerPercentage <= 1, "Power percentage should be normalized")

        let directionDegrees = shot.directionDegrees
        #expect(directionDegrees == 30, "Direction should convert to 30 degrees")
    }

    @Test("Shot result types")
    func testShotResultTypes() async throws {
        let shot = TestFixtures.createTestShot()

        // Test different result types
        shot.complete(at: TestFixtures.pinPosition, result: .holeIn)
        #expect(shot.wasSuccessful, "Hole in should be successful")

        let waterShot = TestFixtures.createTestShot()
        waterShot.complete(at: Position(x: 200, y: 200), result: .waterHazard)
        #expect(!waterShot.wasSuccessful, "Water hazard should not be successful")

        let bunkerShot = TestFixtures.createTestShot()
        bunkerShot.complete(at: Position(x: 150, y: 150), result: .bunker)
        #expect(!bunkerShot.wasSuccessful, "Bunker should not be successful")
    }
}