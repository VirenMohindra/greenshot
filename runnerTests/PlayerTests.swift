//
//  PlayerTests.swift
//  GreenShotTests
//
//  Unit tests for Player entity
//

import Testing
import Foundation
@testable import runner

struct PlayerTests {

    @Test("Player initializes correctly with display name")
    func testPlayerInitialization() async throws {
        let player = Player(displayName: "John Doe")

        #expect(player.displayName == "John Doe", "Player should have correct display name")
        #expect(player.id != UUID(), "Player should have unique ID")
        #expect(player.statistics.roundsPlayed == 0, "Player should start with 0 rounds played")
        #expect(player.statistics.totalStrokes == 0, "Player should start with 0 total strokes")
    }

    @Test("Player round management")
    func testRoundManagement() async throws {
        let player = TestFixtures.createTestPlayer()
        let course = TestFixtures.createTestCourse()

        // Start a new round
        player.startNewRound(on: course)
        #expect(player.currentRound != nil, "Should have current round after starting")

        // Record some scores
        let hole1 = course.holes[0]
        let score1 = Score(strokes: 4, par: hole1.par)
        player.recordScore(score1, for: hole1)

        #expect(player.getCurrentScore() == score1.strokes - score1.par, "Should track current score")
        #expect(player.getCurrentRoundPar() == hole1.par, "Should track current round par")
    }

    @Test("Player statistics tracking after completing rounds")
    func testStatisticsTracking() async throws {
        let player = TestFixtures.createTestPlayer()
        let course = TestFixtures.createTestCourse(holeCount: 3) // Small course for testing

        // Start and complete a round
        player.startNewRound(on: course)

        // Record scores for all holes
        for (index, hole) in course.holes.enumerated() {
            let score = Score(strokes: hole.par + index, par: hole.par) // Progressive scores
            player.recordScore(score, for: hole)
        }

        // Complete the round
        player.currentRound?.completeRound()
        let completedRound = player.completeCurrentRound()

        #expect(completedRound != nil, "Should return completed round")
        #expect(player.statistics.roundsPlayed == 1, "Should have 1 round played")
        #expect(player.statistics.totalStrokes > 0, "Should have recorded strokes")
        #expect(player.statistics.holesCompleted == 3, "Should have completed 3 holes")
    }

    @Test("Player statistics calculations")
    func testStatisticsCalculations() async throws {
        let _ = TestFixtures.createTestPlayer()

        // Manually add some statistics by creating a player with pre-existing stats
        var stats = PlayerStatistics()
        let testRound = Round(courseId: UUID(), courseName: "Test Course")

        // Add some test scores
        let hole1 = TestFixtures.createTestHole(number: 1, par: 4)
        let hole2 = TestFixtures.createTestHole(number: 2, par: 3)

        testRound.recordScore(Score(strokes: 4, par: 4), for: hole1) // Par
        testRound.recordScore(Score(strokes: 2, par: 3), for: hole2) // Birdie
        testRound.completeRound()

        stats.addCompletedRound(testRound)

        let playerWithStats = Player(displayName: "Test Player", statistics: stats)

        #expect(playerWithStats.statistics.averageScore > 0, "Should calculate average score")
        #expect(playerWithStats.statistics.averageScorePerHole > 0, "Should calculate average score per hole")
        #expect(playerWithStats.statistics.birdiePercentage > 0, "Should calculate birdie percentage")
    }

    @Test("Player best scores tracking")
    func testBestScoresTracking() async throws {
        let _ = TestFixtures.createTestPlayer()

        // Create test rounds with different scores
        var stats = PlayerStatistics()

        // Round 1: Score +2
        let round1 = Round(courseId: UUID(), courseName: "Test Course")
        let hole1 = TestFixtures.createTestHole(number: 1, par: 4)
        round1.recordScore(Score(strokes: 6, par: 4), for: hole1)
        round1.completeRound()
        stats.addCompletedRound(round1)

        // Round 2: Score -1 (better)
        let round2 = Round(courseId: UUID(), courseName: "Test Course")
        let hole2 = TestFixtures.createTestHole(number: 1, par: 4)
        round2.recordScore(Score(strokes: 3, par: 4), for: hole2)
        round2.completeRound()
        stats.addCompletedRound(round2)

        let playerWithStats = Player(displayName: "Test Player", statistics: stats)

        #expect(playerWithStats.statistics.bestScore == -1, "Best score should be -1")
        #expect(playerWithStats.statistics.worstScore == 2, "Worst score should be +2")
    }

    @Test("Player score type tracking")
    func testScoreTypeTracking() async throws {
        let _ = TestFixtures.createTestPlayer()
        var stats = PlayerStatistics()

        // Create a round with various score types
        let round = Round(courseId: UUID(), courseName: "Test Course")

        // Par
        let hole1 = TestFixtures.createTestHole(number: 1, par: 4)
        round.recordScore(Score(strokes: 4, par: 4), for: hole1)

        // Birdie
        let hole2 = TestFixtures.createTestHole(number: 2, par: 4)
        round.recordScore(Score(strokes: 3, par: 4), for: hole2)

        // Bogey
        let hole3 = TestFixtures.createTestHole(number: 3, par: 4)
        round.recordScore(Score(strokes: 5, par: 4), for: hole3)

        round.completeRound()
        stats.addCompletedRound(round)

        let playerWithStats = Player(displayName: "Test Player", statistics: stats)

        #expect(playerWithStats.statistics.pars == 1, "Should track pars")
        #expect(playerWithStats.statistics.birdies == 1, "Should track birdies")
        #expect(playerWithStats.statistics.bogeys == 1, "Should track bogeys")
    }
}