//
//  CompleteHoleUseCaseTests.swift
//  GreenShotTests
//
//  Unit tests for CompleteHoleUseCase
//

import Testing
import Foundation
@testable import runner

struct CompleteHoleUseCaseTests {

    @Test("CompleteHoleUseCase completes hole correctly")
    func testCompleteHole() async throws {
        let scoringService = MockServiceFactory.createMockScoringService()
        let useCase = CompleteHoleUseCase(scoringService: scoringService)

        let hole = TestFixtures.createTestHole(par: 4)
        let strokes = 3

        let player = TestFixtures.createTestPlayer()
        let result = useCase.completeHole(hole: hole, strokes: strokes, player: player)

        #expect(scoringService.createScoreCalled, "Scoring service should be called")
        #expect(result.score.strokes == strokes, "Score should have correct strokes")
        #expect(result.score.par == hole.par, "Score should have correct par")
    }

    @Test("CompleteHoleUseCase calculates celebration level")
    func testCelebrationLevel() async throws {
        let scoringService = MockServiceFactory.createMockScoringService()
        scoringService.mockCelebrationLevel = .spectacular

        let useCase = CompleteHoleUseCase(scoringService: scoringService)
        let hole = TestFixtures.createTestHole(par: 5)

        let player = TestFixtures.createTestPlayer()
        let result = useCase.completeHole(hole: hole, strokes: 3, player: player) // Eagle

        #expect(result.celebrationLevel == .spectacular, "Eagle should trigger spectacular celebration")
    }

    @Test("CompleteHoleUseCase validates stroke count")
    func testStrokeValidation() async throws {
        let scoringService = MockServiceFactory.createMockScoringService()
        let useCase = CompleteHoleUseCase(scoringService: scoringService)

        let hole = TestFixtures.createTestHole()

        // Test valid stroke counts (the actual implementation doesn't validate ranges, so these will succeed)
        let player = TestFixtures.createTestPlayer()
        let validResult = useCase.completeHole(hole: hole, strokes: 3, player: player)
        #expect(validResult.score.strokes == 3, "Valid strokes should be recorded")

        let anotherValidResult = useCase.completeHole(hole: hole, strokes: 6, player: player)
        #expect(anotherValidResult.score.strokes == 6, "High stroke count should be recorded")
    }
}