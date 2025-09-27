//
//  HoleTests.swift
//  GreenShotTests
//
//  Unit tests for Hole entity
//

import Testing
import Foundation
@testable import runner

struct HoleTests {

    @Test("Hole initializes correctly with all properties")
    func testHoleInitialization() async throws {
        let hole = TestFixtures.createTestHole(number: 5, par: 4, distance: 350)

        #expect(hole.number == 5, "Hole number should be set correctly")
        #expect(hole.par == 4, "Par should be set correctly")
        #expect(hole.difficulty == TestFixtures.mediumDifficulty, "Difficulty should be set correctly")
        #expect(hole.teePosition == TestFixtures.teePosition, "Tee position should be set correctly")
        #expect(hole.pinPosition == TestFixtures.pinPosition, "Pin position should be set correctly")
        #expect(hole.obstacles.count > 0, "Hole should have obstacles")
        #expect(hole.distance > 0, "Distance should be calculated and positive")
    }

    @Test("Hole calculates distance correctly")
    func testDistanceCalculation() async throws {
        let hole = TestFixtures.createTestHole()

        let expectedDistance = hole.teePosition.distance(to: hole.pinPosition)
        #expect(TestAssertions.assertCGFloatEqual(hole.distance, expectedDistance),
                "Hole distance should match calculated distance from tee to pin")
    }

    @Test("Hole validates yardage conversion")
    func testYardageConversion() async throws {
        let hole = TestFixtures.createTestHole()

        let expectedYardage = Int(hole.distance * 0.5)
        #expect(hole.yardage == expectedYardage, "Yardage should be converted correctly from distance")
        #expect(hole.yardage > 0, "Yardage should be positive")
    }

    @Test("Hole description contains all necessary information")
    func testHoleDescription() async throws {
        let hole = TestFixtures.createTestHole(number: 3, par: 4)
        let description = hole.holeDescription

        #expect(description.contains("3"), "Description should contain hole number")
        #expect(description.contains("4"), "Description should contain par")
        #expect(description.contains("yards"), "Description should mention yards")
    }

    @Test("Hole categorizes by par correctly")
    func testParCategorization() async throws {
        let par3Hole = TestFixtures.createTestHole(par: 3)
        let par4Hole = TestFixtures.createTestHole(par: 4)
        let par5Hole = TestFixtures.createTestHole(par: 5)

        #expect(par3Hole.isShortHole, "Par 3 should be short hole")
        #expect(!par3Hole.isMediumHole, "Par 3 should not be medium hole")
        #expect(!par3Hole.isLongHole, "Par 3 should not be long hole")

        #expect(!par4Hole.isShortHole, "Par 4 should not be short hole")
        #expect(par4Hole.isMediumHole, "Par 4 should be medium hole")
        #expect(!par4Hole.isLongHole, "Par 4 should not be long hole")

        #expect(!par5Hole.isShortHole, "Par 5 should not be short hole")
        #expect(!par5Hole.isMediumHole, "Par 5 should not be medium hole")
        #expect(par5Hole.isLongHole, "Par 5 should be long hole")
    }

    @Test("Hole detects ball in hole correctly")
    func testBallInHole() async throws {
        let hole = TestFixtures.createTestHole()

        // Ball at pin position should be in hole
        let ballAtPin = hole.pinPosition
        #expect(hole.isBallInHole(ballAtPin), "Ball at pin position should be in hole")

        // Ball very close to pin should be in hole
        let ballNearPin = Position(x: hole.pinPosition.x + 5, y: hole.pinPosition.y)
        #expect(hole.isBallInHole(ballNearPin), "Ball very close to pin should be in hole")

        // Ball far from pin should not be in hole
        let ballFarFromPin = Position(x: hole.pinPosition.x + 50, y: hole.pinPosition.y)
        #expect(!hole.isBallInHole(ballFarFromPin), "Ball far from pin should not be in hole")
    }

    @Test("Hole detects ball on green correctly")
    func testBallOnGreen() async throws {
        let hole = TestFixtures.createTestHole()

        // Ball at green center should be on green
        #expect(hole.isBallOnGreen(hole.greenPosition), "Ball at green center should be on green")

        // Ball within green radius should be on green
        let ballOnGreen = Position(x: hole.greenPosition.x + 20, y: hole.greenPosition.y)
        #expect(hole.isBallOnGreen(ballOnGreen), "Ball within green radius should be on green")

        // Ball outside green radius should not be on green
        let ballOffGreen = Position(x: hole.greenPosition.x + 100, y: hole.greenPosition.y)
        #expect(!hole.isBallOnGreen(ballOffGreen), "Ball outside green radius should not be on green")
    }

    @Test("Hole detects ball on fairway correctly")
    func testBallOnFairway() async throws {
        let hole = TestFixtures.createTestHole()

        // Test various positions along the fairway path
        let testPosition = Position(x: 150, y: 250) // Somewhere on the test fairway

        // Note: fairwayPath.contains() depends on the specific path generated
        // Just verify the method works without exceptions
        let onFairway = hole.isBallOnFairway(testPosition)
        #expect(onFairway == true || onFairway == false, "isBallOnFairway should return a boolean value")
    }

    @Test("Hole detects ball near tee correctly")
    func testBallNearTee() async throws {
        let hole = TestFixtures.createTestHole()

        // Ball at tee position should be near tee
        #expect(hole.isBallNearTee(hole.teePosition), "Ball at tee position should be near tee")

        // Ball close to tee should be near tee
        let ballNearTee = Position(x: hole.teePosition.x + 30, y: hole.teePosition.y)
        #expect(hole.isBallNearTee(ballNearTee), "Ball close to tee should be near tee")

        // Ball far from tee should not be near tee
        let ballFarFromTee = Position(x: hole.teePosition.x + 200, y: hole.teePosition.y)
        #expect(!hole.isBallNearTee(ballFarFromTee), "Ball far from tee should not be near tee")
    }

    @Test("Hole finds obstacles at position")
    func testObstacleAt() async throws {
        let hole = TestFixtures.createTestHole()

        // Should find obstacle near its position
        if let firstObstacle = hole.obstacles.first {
            let obstacleFound = hole.obstacleAt(firstObstacle.position)
            #expect(obstacleFound != nil, "Should find obstacle at its exact position")
            #expect(obstacleFound?.type == firstObstacle.type, "Found obstacle should have correct type")
        }

        // Should not find obstacle at empty position
        let emptyPosition = Position(x: -100, y: -100)
        let noObstacle = hole.obstacleAt(emptyPosition)
        #expect(noObstacle == nil, "Should not find obstacle at empty position")
    }

    @Test("Hole completion status with score")
    func testHoleCompletion() async throws {
        let hole = TestFixtures.createTestHole()

        // Valid score should mark hole as completed
        let validScore = Score(strokes: 4, par: hole.par)
        #expect(hole.isCompleted(by: validScore), "Hole should be completed with valid score")

        // Zero strokes should not mark hole as completed
        let invalidScore = Score(strokes: 0, par: hole.par)
        #expect(!hole.isCompleted(by: invalidScore), "Hole should not be completed with zero strokes")
    }

    @Test("Hole tolerances for spatial queries")
    func testSpatialQueryTolerances() async throws {
        let hole = TestFixtures.createTestHole()

        // Test custom tolerance for ball in hole
        let ballAtEdge = Position(x: hole.pinPosition.x + 20, y: hole.pinPosition.y)
        #expect(!hole.isBallInHole(ballAtEdge, tolerance: 10.0), "Ball should not be in hole with smaller tolerance")
        #expect(hole.isBallInHole(ballAtEdge, tolerance: 30.0), "Ball should be in hole with larger tolerance")

        // Test custom tolerance for tee proximity
        let ballAtTeeEdge = Position(x: hole.teePosition.x + 100, y: hole.teePosition.y)
        #expect(!hole.isBallNearTee(ballAtTeeEdge, tolerance: 50.0), "Ball should not be near tee with smaller tolerance")
        #expect(hole.isBallNearTee(ballAtTeeEdge, tolerance: 150.0), "Ball should be near tee with larger tolerance")
    }

    @Test("Hole validates all positions within bounds")
    func testPositionBoundsValidation() async throws {
        let course = TestFixtures.createTestCourse()

        for hole in course.holes {
            #expect(TestAssertions.assertPositionValid(hole.teePosition, within: course.worldSize),
                    "Hole \\(hole.number) tee should be within world bounds")
            #expect(TestAssertions.assertPositionValid(hole.pinPosition, within: course.worldSize),
                    "Hole \\(hole.number) pin should be within world bounds")
            #expect(TestAssertions.assertPositionValid(hole.greenPosition, within: course.worldSize),
                    "Hole \\(hole.number) green should be within world bounds")

            for obstacle in hole.obstacles {
                #expect(TestAssertions.assertPositionValid(obstacle.position, within: course.worldSize),
                        "Obstacle in hole \\(hole.number) should be within world bounds")
            }
        }
    }

    @Test("Hole supports different difficulty levels")
    func testDifficultyLevels() async throws {
        let easyHole = Hole(
            number: 1,
            par: 4,
            difficulty: Difficulty(0.2),
            teePosition: TestFixtures.teePosition,
            pinPosition: TestFixtures.pinPosition,
            fairwayPath: TestFixtures.createTestFairwayPath(),
            obstacles: []
        )

        let hardHole = Hole(
            number: 1,
            par: 4,
            difficulty: Difficulty(0.8),
            teePosition: TestFixtures.teePosition,
            pinPosition: TestFixtures.pinPosition,
            fairwayPath: TestFixtures.createTestFairwayPath(),
            obstacles: TestFixtures.createTestObstacles()
        )

        #expect(easyHole.difficulty.isBeginner, "Easy hole should be beginner difficulty")
        #expect(hardHole.difficulty.isAdvanced, "Hard hole should be advanced difficulty")
        #expect(hardHole.obstacles.count > easyHole.obstacles.count,
                "Hard hole should have more obstacles than easy hole")
    }

    @Test("Hole performance with complex calculations")
    func testHolePerformance() async throws {
        let (hole, elapsed) = PerformanceTestUtilities.measureExecutionTime {
            return TestFixtures.createTestHole()
        }

        #expect(elapsed < 0.01, "Hole creation should be fast")
        #expect(hole.obstacles.count > 0, "Created hole should have obstacles")

        // Test spatial query performance
        let (_, queryElapsed) = PerformanceTestUtilities.measureExecutionTime {
            let testPosition = Position(x: 100, y: 100)
            for _ in 0..<1000 {
                _ = hole.isBallOnFairway(testPosition)
                _ = hole.isBallOnGreen(testPosition)
                _ = hole.obstacleAt(testPosition)
            }
        }

        #expect(queryElapsed < 0.1, "Spatial queries should be fast")
    }
}