//
//  ScoringServiceTests.swift
//  runnerTests
//
//  Unit tests for scoring service calculations
//

import Testing
import Foundation
@testable import runner

struct ScoringServiceTests {

    let scoringService = ScoringService()

    @Test("Scoring service calculates par correctly for different distances")
    func testCalculateParForDistance() async throws {
        let difficulty = Difficulty(0.5) // Medium difficulty

        // Test Par 3 range
        let par3Distance: CGFloat = 180
        let par3 = scoringService.calculateParForDistance(par3Distance, difficulty: difficulty)
        #expect(par3 == 3, "180 yards should be Par 3")

        // Test Par 4 range
        let par4Distance: CGFloat = 350
        let par4 = scoringService.calculateParForDistance(par4Distance, difficulty: difficulty)
        #expect(par4 == 4, "350 yards should be Par 4")

        // Test Par 5 range
        let par5Distance: CGFloat = 500
        let par5 = scoringService.calculateParForDistance(par5Distance, difficulty: difficulty)
        #expect(par5 == 5, "500 yards should be Par 5")
    }

    @Test("Scoring service creates correct score quality mapping")
    func testCreateScore() async throws {
        // Test Eagle (2 under par)
        let eagleScore = scoringService.createScore(strokes: 3, par: 5)
        #expect(eagleScore.isEagle, "3 strokes on par 5 should be Eagle")
        #expect(eagleScore.celebrationText.contains("Eagle"), "Eagle should have appropriate celebration text")

        // Test Birdie (1 under par)
        let birdieScore = scoringService.createScore(strokes: 3, par: 4)
        #expect(birdieScore.isBirdie, "3 strokes on par 4 should be Birdie")
        #expect(birdieScore.celebrationText.contains("Birdie"), "Birdie should have appropriate celebration text")

        // Test Par (exact par)
        let parScore = scoringService.createScore(strokes: 4, par: 4)
        #expect(parScore.isPar, "4 strokes on par 4 should be Par")

        // Test Bogey (1 over par)
        let bogeyScore = scoringService.createScore(strokes: 5, par: 4)
        #expect(bogeyScore.isBogey, "5 strokes on par 4 should be Bogey")
        #expect(bogeyScore.celebrationText.contains("Bogey"), "Bogey should have appropriate celebration text")

        // Test Double Bogey (2 over par)
        let doubleBogeyScore = scoringService.createScore(strokes: 6, par: 4)
        #expect(doubleBogeyScore.isDoubleBogey, "6 strokes on par 4 should be Double Bogey")
    }

    @Test("Scoring service provides correct celebration levels")
    func testGetCelebrationLevel() async throws {
        let eagleScore = Score(strokes: 3, par: 5)
        let birdieScore = Score(strokes: 3, par: 4)
        let parScore = Score(strokes: 4, par: 4)
        let bogeyScore = Score(strokes: 5, par: 4)

        let eagleLevel = scoringService.getCelebrationLevel(eagleScore)
        let birdieLevel = scoringService.getCelebrationLevel(birdieScore)
        let parLevel = scoringService.getCelebrationLevel(parScore)
        let bogeyLevel = scoringService.getCelebrationLevel(bogeyScore)

        // Eagle should have highest celebration
        #expect(eagleLevel.rawValue > birdieLevel.rawValue, "Eagle should have higher celebration than Birdie")
        #expect(birdieLevel.rawValue > parLevel.rawValue, "Birdie should have higher celebration than Par")
        #expect(parLevel.rawValue > bogeyLevel.rawValue, "Par should have higher celebration than Bogey")
    }

    @Test("Scoring service calculates total scores correctly")
    func testCalculateTotalScore() async throws {
        let scores = [
            Score(strokes: 4, par: 4), // Par
            Score(strokes: 3, par: 4), // Birdie (-1)
            Score(strokes: 5, par: 4)  // Bogey (+1)
        ]

        let totalScore = scoringService.calculateTotalScore(scores)
        #expect(totalScore.totalStrokes == 12, "Total strokes should be 12")
        #expect(totalScore.totalPar == 12, "Total par should be 12")
        #expect(totalScore.scoreToPar == 0, "Score should be even (0)")
    }

    @Test("Scoring service validates par values")
    func testParValidation() async throws {
        // Valid par values
        #expect(scoringService.isValidPar(3), "Par 3 should be valid")
        #expect(scoringService.isValidPar(4), "Par 4 should be valid")
        #expect(scoringService.isValidPar(5), "Par 5 should be valid")

        // Invalid par values
        #expect(!scoringService.isValidPar(2), "Par 2 should be invalid")
        #expect(!scoringService.isValidPar(6), "Par 6 should be invalid")
        #expect(!scoringService.isValidPar(0), "Par 0 should be invalid")
    }
}