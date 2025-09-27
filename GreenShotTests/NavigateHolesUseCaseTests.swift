//
//  NavigateHolesUseCaseTests.swift
//  GreenShotTests
//
//  Unit tests for NavigateHolesUseCase
//

import Testing
import Foundation
@testable import GreenShot

struct NavigateHolesUseCaseTests {

    @Test("NavigateHolesUseCase starts new round")
    func testStartNewRound() async throws {
        let useCase = NavigateHolesUseCase()
        let course = TestFixtures.createTestCourse(holeCount: 9)
        let player = TestFixtures.createTestPlayer()

        let result = useCase.startNewRound(player: player, course: course)

        switch result {
        case .success(let hole):
            #expect(hole.number == 1, "Should start with hole 1")
            #expect(player.currentRound != nil, "Player should have active round")
        case .failure(let error):
            #expect(Bool(false), "Should not fail: \(error)")
        }
    }

    @Test("NavigateHolesUseCase moves to next hole")
    func testMoveToNextHole() async throws {
        let useCase = NavigateHolesUseCase()
        let course = TestFixtures.createTestCourse(holeCount: 9)
        let player = TestFixtures.createTestPlayer()

        // Start round first
        _ = useCase.startNewRound(player: player, course: course)

        let result = useCase.moveToNextHole(course: course, player: player)

        switch result {
        case .success(let hole, let progress, let isLastHole):
            #expect(hole.number == 2, "Should move to hole 2")
            #expect(progress.contains("2"), "Progress should mention hole 2")
            #expect(!isLastHole, "Should not be last hole")
        case .roundComplete:
            #expect(Bool(false), "Should not complete round on second hole")
        }
    }

    @Test("NavigateHolesUseCase handles round completion")
    func testRoundCompletion() async throws {
        let useCase = NavigateHolesUseCase()
        let course = TestFixtures.createTestCourse(holeCount: 2) // Small course for testing
        let player = TestFixtures.createTestPlayer()

        // Start round
        _ = useCase.startNewRound(player: player, course: course)

        // Move to last hole
        _ = useCase.moveToNextHole(course: course, player: player)

        // Try to move past last hole
        let result = useCase.moveToNextHole(course: course, player: player)

        switch result {
        case .success:
            #expect(Bool(false), "Should not succeed past last hole")
        case .roundComplete(let completionResult):
            switch completionResult {
            case .success(let _, let totalStrokes, let totalPar, let completedRound):
                #expect(totalStrokes >= 0, "Total strokes should be non-negative")
                #expect(totalPar > 0, "Total par should be positive")
                #expect(completedRound.isComplete, "Round should be marked complete")
            case .failure(let error):
                #expect(Bool(false), "Round completion should not fail: \(error)")
            }
        }
    }

    @Test("NavigateHolesUseCase resets ball to tee")
    func testResetToTee() async throws {
        let useCase = NavigateHolesUseCase()
        let hole = TestFixtures.createTestHole()
        let ball = TestFixtures.createTestBall(at: Position(x: 200, y: 200))

        let result = useCase.resetToTee(ball: ball, currentHole: hole)

        switch result {
        case .success(let newPosition):
            #expect(newPosition == hole.teePosition, "Ball should be reset to tee position")
            #expect(ball.position == hole.teePosition, "Ball's actual position should be updated")
        case .failure(let error):
            #expect(Bool(false), "Reset should not fail: \(error)")
        }
    }

    @Test("NavigateHolesUseCase completes round correctly")
    func testCompleteRound() async throws {
        let useCase = NavigateHolesUseCase()
        let course = TestFixtures.createTestCourse(holeCount: 2)
        let player = TestFixtures.createTestPlayer()

        // Start round and add some scores
        _ = useCase.startNewRound(player: player, course: course)

        // Record some scores
        let hole1 = course.holes[0]
        let score1 = Score(strokes: 4, par: hole1.par)
        player.recordScore(score1, for: hole1)

        let result = useCase.completeRound(course: course, player: player)

        switch result {
        case .success(let _, let totalStrokes, let totalPar, let completedRound):
            #expect(totalStrokes == 4, "Total strokes should be 4")
            #expect(totalPar == hole1.par, "Total par should match hole par")
            #expect(completedRound.isComplete, "Round should be complete")
        case .failure(let error):
            #expect(Bool(false), "Complete round should not fail: \(error)")
        }
    }
}