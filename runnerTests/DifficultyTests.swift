//
//  DifficultyTests.swift
//  runnerTests
//
//  Unit tests for Difficulty value object
//

import Testing
import Foundation
@testable import runner

struct DifficultyTests {

    @Test("Difficulty initializes with level correctly")
    func testDifficultyInitialization() async throws {
        let difficulty = Difficulty(0.5)

        #expect(difficulty.level == 0.5, "Difficulty level should be set correctly")
    }

    @Test("Difficulty clamps values to valid range")
    func testDifficultyRangeClamping() async throws {
        let tooLow = Difficulty(-0.5)
        let tooHigh = Difficulty(1.5)
        let valid = Difficulty(0.7)

        #expect(tooLow.level == 0.0, "Negative values should clamp to 0.0")
        #expect(tooHigh.level == 1.0, "Values over 1.0 should clamp to 1.0")
        #expect(valid.level == 0.7, "Valid values should remain unchanged")
    }

    @Test("Difficulty initializes with Double correctly")
    func testDifficultyDoubleInitialization() async throws {
        let difficulty = Difficulty(level: 0.6)

        #expect(TestAssertions.assertFloatEqual(difficulty.level, 0.6), "Difficulty should convert Double to Float correctly")
    }

    @Test("Difficulty initializes from hole number correctly")
    func testDifficultyHoleNumberInitialization() async throws {
        let firstHole = Difficulty(holeNumber: 1, totalHoles: 18)
        let lastHole = Difficulty(holeNumber: 18, totalHoles: 18)
        let middleHole = Difficulty(holeNumber: 9, totalHoles: 18)

        #expect(firstHole.level == 0.0, "First hole should have minimum difficulty")
        #expect(lastHole.level == 1.0, "Last hole should have maximum difficulty")
        #expect(middleHole.level > 0.0 && middleHole.level < 1.0, "Middle holes should have intermediate difficulty")
    }

    @Test("Difficulty categorization works correctly")
    func testDifficultyCategories() async throws {
        let beginner = Difficulty(0.2)
        let intermediate = Difficulty(0.5)
        let advanced = Difficulty(0.8)

        #expect(beginner.isBeginner, "Low difficulty should be beginner")
        #expect(!beginner.isIntermediate, "Low difficulty should not be intermediate")
        #expect(!beginner.isAdvanced, "Low difficulty should not be advanced")

        #expect(!intermediate.isBeginner, "Medium difficulty should not be beginner")
        #expect(intermediate.isIntermediate, "Medium difficulty should be intermediate")
        #expect(!intermediate.isAdvanced, "Medium difficulty should not be advanced")

        #expect(!advanced.isBeginner, "High difficulty should not be beginner")
        #expect(!advanced.isIntermediate, "High difficulty should not be intermediate")
        #expect(advanced.isAdvanced, "High difficulty should be advanced")
    }

    @Test("Difficulty display names are correct")
    func testDifficultyDisplayNames() async throws {
        let beginner = Difficulty(0.1)
        let intermediate = Difficulty(0.5)
        let advanced = Difficulty(0.9)

        #expect(beginner.displayName == "Beginner", "Beginner difficulty should have correct display name")
        #expect(intermediate.displayName == "Intermediate", "Intermediate difficulty should have correct display name")
        #expect(advanced.displayName == "Advanced", "Advanced difficulty should have correct display name")
    }

    @Test("Difficulty affects fairway width correctly")
    func testFairwayWidth() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.fairwayWidth > hard.fairwayWidth, "Easier difficulties should have wider fairways")
        #expect(easy.fairwayWidth == 100.0, "Easiest difficulty should have maximum fairway width")
        #expect(hard.fairwayWidth == 70.0, "Hardest difficulty should have minimum fairway width")
    }

    @Test("Difficulty affects obstacle count correctly")
    func testObstacleCount() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.obstacleCount < hard.obstacleCount, "Harder difficulties should have more obstacles")
        #expect(easy.obstacleCount == 1, "Easiest difficulty should have minimum obstacles")
        #expect(hard.obstacleCount == 6, "Hardest difficulty should have maximum obstacles")
    }

    @Test("Difficulty affects water hazard chance correctly")
    func testWaterHazardChance() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.waterHazardChance < hard.waterHazardChance, "Harder difficulties should have higher water hazard chance")
        #expect(TestAssertions.assertFloatEqual(easy.waterHazardChance, 0.2), "Easiest difficulty should have 20% water hazard chance")
        #expect(TestAssertions.assertFloatEqual(hard.waterHazardChance, 0.8), "Hardest difficulty should have 80% water hazard chance")
    }

    @Test("Difficulty affects bunker count correctly")
    func testBunkerCount() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.bunkerCount < hard.bunkerCount, "Harder difficulties should have more bunkers")
        #expect(easy.bunkerCount == 3, "Easiest difficulty should have minimum bunkers")
        #expect(hard.bunkerCount == 9, "Hardest difficulty should have maximum bunkers")
    }

    @Test("Difficulty affects tree count correctly")
    func testTreeCount() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.treeCount < hard.treeCount, "Harder difficulties should have more trees")
        #expect(easy.treeCount == 8, "Easiest difficulty should have minimum trees")
        #expect(hard.treeCount == 20, "Hardest difficulty should have maximum trees")
    }

    @Test("Difficulty affects course curvature correctly")
    func testCourseCurvature() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.courseCurvature < hard.courseCurvature, "Harder difficulties should have more curvature")
        #expect(easy.courseCurvature == 0.0, "Easiest difficulty should have no curvature")
        #expect(TestAssertions.assertFloatEqual(hard.courseCurvature, 0.7), "Hardest difficulty should have maximum curvature")
    }

    @Test("Difficulty affects hole position variation correctly")
    func testHolePositionVariation() async throws {
        let easy = Difficulty(0.0)
        let hard = Difficulty(1.0)

        #expect(easy.holePositionVariation < hard.holePositionVariation, "Harder difficulties should have more position variation")
        #expect(easy.holePositionVariation == 0.0, "Easiest difficulty should have no position variation")
        #expect(TestAssertions.assertCGFloatEqual(hard.holePositionVariation, 0.35), "Hardest difficulty should have maximum position variation")
    }

    @Test("Difficulty constants are correct")
    func testDifficultyConstants() async throws {
        #expect(Difficulty.beginner.level == 0.0, "Beginner constant should be 0.0")
        #expect(Difficulty.intermediate.level == 0.5, "Intermediate constant should be 0.5")
        #expect(Difficulty.advanced.level == 1.0, "Advanced constant should be 1.0")
    }

    @Test("Difficulty supports Equatable correctly")
    func testDifficultyEquatable() async throws {
        let difficulty1 = Difficulty(0.5)
        let difficulty2 = Difficulty(0.5)
        let difficulty3 = Difficulty(0.7)

        #expect(difficulty1 == difficulty2, "Identical difficulties should be equal")
        #expect(difficulty1 != difficulty3, "Different difficulties should not be equal")
    }

    @Test("Difficulty supports Hashable correctly")
    func testDifficultyHashable() async throws {
        let difficulty1 = Difficulty(0.5)
        let difficulty2 = Difficulty(0.5)
        let difficulty3 = Difficulty(0.7)

        #expect(difficulty1.hashValue == difficulty2.hashValue, "Identical difficulties should have same hash")
        #expect(difficulty1.hashValue != difficulty3.hashValue, "Different difficulties should have different hash")
    }

    @Test("Difficulty progressive scaling works correctly")
    func testProgressiveScaling() async throws {
        let holes = (1...18).map { Difficulty(holeNumber: $0, totalHoles: 18) }

        // Check that difficulty progresses
        for i in 0..<holes.count-1 {
            #expect(holes[i].level <= holes[i+1].level, "Difficulty should increase or stay same throughout round")
        }

        #expect(holes.first?.level == 0.0, "First hole should have minimum difficulty")
        #expect(holes.last?.level == 1.0, "Last hole should have maximum difficulty")
    }
}