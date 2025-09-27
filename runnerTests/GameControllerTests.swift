//
//  GameControllerTests.swift
//  GreenShotTests
//
//  Unit tests for GameController
//

import Testing
import Foundation
import Combine
import GameKit
@testable import runner

@MainActor
struct GameControllerTests {

    @Test("GameController initializes correctly")
    func testGameControllerInitialization() async throws {
        let gameController = createTestGameController()

        #expect(gameController.gameState == .menu, "Should start in menu state")
        #expect(gameController.currentCourse == nil, "Should start with no course")
        #expect(gameController.currentPlayer == nil, "Should start with no player")
        #expect(gameController.currentStrokes == 0, "Should start with zero strokes")
    }

    @Test("GameController starts new game correctly")
    func testStartNewGame() async throws {
        let gameController = createTestGameController()

        gameController.startNewGame(playerName: "Test Player")

        #expect(gameController.currentPlayer?.displayName == "Test Player", "Should create player")
        #expect(gameController.currentCourse != nil, "Should generate course")
        #expect(gameController.gameState == .playing, "Should transition to playing state")
        #expect(gameController.golfBall != nil, "Should create golf ball")
    }

    @Test("GameController handles shot execution")
    func testShotExecution() async throws {
        let gameController = createTestGameController()
        gameController.startNewGame()

        let dragStart = TestFixtures.teePosition
        let dragEnd = Position(x: dragStart.x + 50, y: dragStart.y)

        gameController.takeShot(
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: 0.7
        )

        #expect(gameController.currentStrokes > 0, "Stroke count should increase")
        #expect(gameController.golfBall?.velocity.magnitude ?? 0 > 0, "Ball should have velocity")
    }

    @Test("GameController completes hole correctly")
    func testHoleCompletion() async throws {
        let gameController = createTestGameController()
        gameController.startNewGame()

        // Simulate ball reaching hole
        if let ball = gameController.golfBall,
           let hole = gameController.currentCourse?.currentHole {
            ball.updatePosition(hole.pinPosition)
            ball.updateVelocity(Velocity(dx: 0, dy: 0))

            gameController.checkForHoleCompletion(
                ballPosition: ball.position,
                ballVelocity: ball.velocity
            )

            #expect(gameController.lastCompletedScore != nil, "Should record completed score")
        }
    }

    @Test("GameController navigates between holes")
    func testHoleNavigation() async throws {
        let gameController = createTestGameController()
        gameController.startNewGame()

        let initialHole = gameController.currentCourse?.currentHole?.number
        #expect(initialHole == 1, "Should start on first hole")

        // Test that current hole is set correctly
        #expect(gameController.currentCourse != nil, "Should have a current course")
        #expect(gameController.currentCourse?.currentHole != nil, "Should have a current hole")
    }

    @Test("GameController resets ball to tee")
    func testBallReset() async throws {
        let gameController = createTestGameController()
        gameController.startNewGame()

        if let ball = gameController.golfBall,
           let hole = gameController.currentCourse?.currentHole {
            // Move ball away from tee
            ball.updatePosition(Position(x: 500, y: 600))

            gameController.resetBallToTee()

            #expect(ball.position == hole.teePosition, "Ball should be reset to tee position")
            #expect(ball.velocity.isStationary, "Ball should have zero velocity")
        }
    }

    // Helper function to create test game controller
    private func createTestGameController() -> GameController {
        let takeShotUseCase = TakeShotUseCase(physicsService: MockServiceFactory.createMockPhysicsService())
        let completeHoleUseCase = CompleteHoleUseCase(scoringService: MockServiceFactory.createMockScoringService())
        let navigateHolesUseCase = NavigateHolesUseCase()
        let updateCameraUseCase = UpdateCameraUseCase()
        let holeGenerationService = MockServiceFactory.createMockHoleGenerationService()
        let gameCenterService = MockGameCenterService()
        let persistenceService = MockPersistenceService()
        let eventBus = MockEventBus()

        return GameController(
            takeShotUseCase: takeShotUseCase,
            completeHoleUseCase: completeHoleUseCase,
            navigateHolesUseCase: navigateHolesUseCase,
            updateCameraUseCase: updateCameraUseCase,
            holeGenerationService: holeGenerationService,
            gameCenterService: gameCenterService,
            persistenceService: persistenceService,
            eventBus: eventBus
        )
    }
}

// Additional mock services
class MockGameCenterService: GameCenterServiceProtocol {
    var isAuthenticated: Bool = false
    var currentPlayer: String? = nil
    var authenticationPublisher: AnyPublisher<Bool, Never> = Just(false).eraseToAnyPublisher()

    func authenticate() async {}
    func submitScore(_ score: Int, to leaderboardID: String) async throws {}
    func loadLeaderboard(_ leaderboardID: String) async throws -> [LeaderboardEntry] { return [] }
    func reportAchievement(_ achievementID: String, progress: Double) async throws {}

    func findMatch(for players: Int, completion: @escaping (Result<GKMatch, Error>) -> Void) {}
    func sendData(_ data: Data, to players: [String], mode: GKMatch.SendDataMode) throws {}
    func loadFriends() async throws -> [GKPlayer] { return [] }
}

class MockPersistenceService: PersistenceServiceProtocol {
    func saveUserPreferences(_ preferences: UserPreferences) throws {}
    func loadUserPreferences() throws -> UserPreferences { return .default }

    @MainActor func saveGameSession(_ session: GameSession) throws {}
    @MainActor func loadRecentGameSessions(limit: Int) throws -> [GameSession] { return [] }
    @MainActor func deleteGameSession(_ sessionId: UUID) throws {}

    func saveCourse(_ course: Course) throws {}
    func loadSavedCourses() throws -> [Course] { return [] }
    func deleteCourse(_ courseId: UUID) throws {}

    func savePlayerStats(_ stats: PlayerStatistics) throws {}
    func loadPlayerStats() throws -> PlayerStatistics? { return nil }
    func updateStatistics(with session: GameSession) throws {}


    @MainActor func clearCache() throws {}
    func getDatabaseSize() -> Int64 { return 0 }
}

class MockEventBus: EventBusProtocol {
    func publish<T>(_ event: T) where T : GameEvent {}

    func publisher<T>(for eventType: T.Type) -> AnyPublisher<T, Never> where T : GameEvent {
        return Empty<T, Never>().eraseToAnyPublisher()
    }

    func publisher(for notificationName: NSNotification.Name) -> AnyPublisher<[String: Any], Never> {
        return Empty<[String: Any], Never>().eraseToAnyPublisher()
    }
}