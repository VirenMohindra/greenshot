//
//  GameController.swift
//  runner
//
//  Main game coordinator managing all use cases and game state
//

import Foundation
import Combine

@MainActor
class GameController: ObservableObject {
    // MARK: - Published Properties
    @Published private(set) var gameState: GameState = .menu
    @Published private(set) var currentCourse: Course?
    @Published private(set) var currentPlayer: Player?
    @Published private(set) var golfBall: GolfBall?
    @Published private(set) var currentStrokes: Int = 0

    // Celebration tracking
    @Published private(set) var lastCompletedScore: Score?
    @Published private(set) var lastCelebrationLevel: CelebrationLevel = .none

    // GameCenter integration
    @Published private(set) var isGameCenterAuthenticated: Bool = false
    @Published private(set) var gameCenterPlayer: String?
    @Published private(set) var totalScore: Int = 0

    // MARK: - Use Cases
    private let takeShotUseCase: TakeShotUseCaseProtocol
    private let completeHoleUseCase: CompleteHoleUseCaseProtocol
    private let navigateHolesUseCase: NavigateHolesUseCaseProtocol
    private let updateCameraUseCase: UpdateCameraUseCaseProtocol

    // MARK: - Services
    private let holeGenerationService: HoleGenerationServiceProtocol
    private let gameCenterService: GameCenterServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let eventBus: EventBusProtocol

    // MARK: - Game State
    private let courseWorldSize = CGSize(width: 800, height: 1600)
    private var isCurrentHoleCompleted = false
    private var cancellables = Set<AnyCancellable>()
    private var currentGameSession: GameSession?

    init(
        takeShotUseCase: TakeShotUseCaseProtocol,
        completeHoleUseCase: CompleteHoleUseCaseProtocol,
        navigateHolesUseCase: NavigateHolesUseCaseProtocol,
        updateCameraUseCase: UpdateCameraUseCaseProtocol,
        holeGenerationService: HoleGenerationServiceProtocol,
        gameCenterService: GameCenterServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        eventBus: EventBusProtocol
    ) {
        self.takeShotUseCase = takeShotUseCase
        self.completeHoleUseCase = completeHoleUseCase
        self.navigateHolesUseCase = navigateHolesUseCase
        self.updateCameraUseCase = updateCameraUseCase
        self.holeGenerationService = holeGenerationService
        self.gameCenterService = gameCenterService
        self.persistenceService = persistenceService
        self.eventBus = eventBus

        setupGameCenterSubscriptions()
    }

    private func setupGameCenterSubscriptions() {
        // Setup subscriptions on main actor
        Task { @MainActor in
            // Subscribe to GameCenter authentication changes
            gameCenterService.authenticationPublisher
                .receive(on: DispatchQueue.main)
                .assign(to: \.isGameCenterAuthenticated, on: self)
                .store(in: &cancellables)

            // Update initial values
            isGameCenterAuthenticated = gameCenterService.isAuthenticated
            gameCenterPlayer = gameCenterService.currentPlayer
        }
    }
}

// MARK: - Game Management
extension GameController {
    func startNewGame(playerName: String = "Player") {
        // Create player
        currentPlayer = Player(displayName: playerName)

        // Generate course
        currentCourse = holeGenerationService.generateCourse(
            holeCount: 9,
            name: "Generated Course",
            worldSize: courseWorldSize
        )

        guard let player = currentPlayer,
              let course = currentCourse else { return }

        // Start round
        let result = navigateHolesUseCase.startNewRound(player: player, course: course)

        switch result {
        case .success(let hole):
            setupForHole(hole)
            gameState = .playing

            // Start new game session for persistence
            startNewGameSession()

            // Publish game started event
            eventBus.publish(GameStartedEvent())

            // Post notification for scene to update
            NotificationCenter.default.post(name: NSNotification.Name("GameStateChanged"), object: nil)

        case .failure(let error):
            print("❌ Failed to start game: \(error)")
        }
    }

    func pauseGame() {
        gameState = .paused
        NotificationCenter.default.post(name: NSNotification.Name("GameStateChanged"), object: nil)
    }

    func resumeGame() {
        gameState = .playing
        NotificationCenter.default.post(name: NSNotification.Name("GameStateChanged"), object: nil)
    }

    func endGame() {
        guard let course = currentCourse,
              let player = currentPlayer else { return }

        let result = navigateHolesUseCase.completeRound(course: course, player: player)

        switch result {
        case .success(let finalScore, _, _, _):
            totalScore = finalScore
            print("🏆 Game completed with score: \(finalScore)")

            // Complete game session for persistence
            completeGameSession()

            // Create a Score object for the event - using total strokes and total par
            let totalPar = currentCourse?.holes.reduce(0) { $0 + $1.par } ?? 36
            let score = Score(strokes: finalScore, par: totalPar)
            eventBus.publish(GameEndedEvent(finalScore: score))

            // Submit score to GameCenter
            Task {
                await submitScoreToGameCenter(finalScore)
            }

            gameState = .gameOver

        case .failure(let error):
            print("❌ Failed to end game: \(error)")
        }
    }

    private func submitScoreToGameCenter(_ score: Int) async {
        do {
            try await gameCenterService.submitScore(score, to: "com.runner.leaderboard.total_score")
            print("✅ Score submitted to GameCenter: \(score)")
        } catch {
            print("❌ Failed to submit score to GameCenter: \(error)")
        }
    }
}

// MARK: - Shot Management
extension GameController {
    func takeShot(dragStart: Position, dragEnd: Position, power: CGFloat) {
        guard let ball = golfBall,
              let hole = currentCourse?.currentHole,
              gameState == .playing else { return }

        let _ = takeShotUseCase.executeShot(
            ball: ball,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: power,
            hole: hole
        )

        // Calculate the impulse that should be applied to the physics body
        let impulse = Velocity(
            dx: (dragEnd.x - dragStart.x) * power,
            dy: (dragEnd.y - dragStart.y) * power
        )

        // Update state asynchronously to avoid SwiftUI warnings
        DispatchQueue.main.async {
            self.currentStrokes += 1
            print("🏌️ Shot taken! Strokes: \(self.currentStrokes)")

            // Publish shot taken event via EventBus
            let shotEvent = ShotTakenEvent(
                power: Float(power),
                direction: 0.0, // Calculate direction from drag vectors
                impulse: impulse
            )
            self.eventBus.publish(shotEvent)

            // Post NSNotification for SpriteKit scene to apply physics impulse
            NotificationCenter.default.post(
                name: NSNotification.Name("ShotTaken"),
                object: nil,
                userInfo: ["impulse": impulse]
            )
            print("📢 Posted ShotTaken notification with impulse: \(impulse)")
        }
    }

    func previewShot(dragStart: Position, dragEnd: Position, power: CGFloat) -> [Position] {
        guard let ball = golfBall else { return [] }

        return takeShotUseCase.previewTrajectory(
            from: ball.position,
            dragStart: dragStart,
            dragEnd: dragEnd,
            power: power
        )
    }

    func resetBallToTee() {
        guard let ball = golfBall,
              let hole = currentCourse?.currentHole else { return }

        let result = navigateHolesUseCase.resetToTee(ball: ball, currentHole: hole)

        switch result {
        case .success(let newPosition):
            print("🔄 Ball reset to tee at: \(newPosition)")

        case .failure(let error):
            print("❌ Failed to reset ball: \(error)")
        }
    }
}

// MARK: - Hole Management
extension GameController {
    func checkForHoleCompletion(ballPosition: Position, ballVelocity: Velocity) {
        guard let hole = currentCourse?.currentHole,
              let _ = currentPlayer,
              !isCurrentHoleCompleted else { return }

        let isCompleted = completeHoleUseCase.checkHoleCompletion(
            ballPosition: ballPosition,
            hole: hole,
            ballVelocity: ballVelocity
        )

        if isCompleted {
            isCurrentHoleCompleted = true
            completeCurrentHole()
        }
    }

    private func completeCurrentHole() {
        guard let hole = currentCourse?.currentHole,
              let player = currentPlayer else { return }

        let result = completeHoleUseCase.completeHole(
            hole: hole,
            strokes: currentStrokes,
            player: player
        )

        print("⛳ Hole completed! Score: \(result.score.displayText)")

        // Create HoleScore for persistence
        let holeScore = HoleScore(
            holeNumber: hole.number,
            par: hole.par,
            strokes: currentStrokes
        )

        // Update game session with hole completion
        updateGameSession(withHoleScore: holeScore)

        // Publish hole completed event
        eventBus.publish(HoleCompletedEvent(hole: hole, score: result.score))

        // Publish celebration data for UI
        lastCompletedScore = result.score
        lastCelebrationLevel = result.celebrationLevel

        // Handle celebrations and achievements
        if result.celebrationLevel.shouldShowMessage {
            print("🎉 \(result.score.celebrationText)")
        }

        for achievement in result.newAchievements {
            print("🏆 Achievement unlocked: \(achievement.title)")
        }

        // Move to next hole after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + result.celebrationLevel.duration) {
            self.moveToNextHole()
        }
    }

    private func moveToNextHole() {
        guard let course = currentCourse,
              let player = currentPlayer else { return }

        let result = navigateHolesUseCase.moveToNextHole(course: course, player: player)

        switch result {
        case .success(let hole, let progress, _):
            print("➡️ Moving to \(progress)")
            setupForHole(hole)

        case .roundComplete(let completionResult):
            switch completionResult {
            case .success(let finalScore, _, _, _):
                print("🏁 Round complete! Final score: \(finalScore)")
                gameState = .gameOver

            case .failure(let error):
                print("❌ Failed to complete round: \(error)")
            }
        }
    }

    private func setupForHole(_ hole: Hole) {
        // Reset stroke count
        currentStrokes = 0

        // Reset hole completion flag
        isCurrentHoleCompleted = false

        // Position ball at tee
        golfBall = GolfBall(position: hole.teePosition)

        print("🏌️ Starting hole \(hole.number) - Par \(hole.par)")

        // Trigger @Published update for course changes (hole progression)
        DispatchQueue.main.async {
            // Force @Published currentCourse to update by re-assigning it
            let course = self.currentCourse
            self.currentCourse = course

            // Publish game state change event via EventBus
            let gameStateEvent = GameStateChangedEvent(newState: self.gameState)
            self.eventBus.publish(gameStateEvent)
        }
    }
}

// MARK: - Camera Management
extension GameController {
    func updateCameraForBall(
        currentCameraPosition: Position,
        screenSize: CGSize
    ) -> CameraUpdateResult {
        guard let ball = golfBall else { return .noUpdate }

        return updateCameraUseCase.followBall(
            cameraPosition: currentCameraPosition,
            ballPosition: ball.position,
            ballVelocity: ball.velocity,
            courseSize: courseWorldSize,
            screenSize: screenSize
        )
    }

    func focusCameraOn(position: Position, screenSize: CGSize, immediate: Bool = false) -> CameraUpdateResult {
        return updateCameraUseCase.focusOnPosition(
            targetPosition: position,
            courseSize: courseWorldSize,
            screenSize: screenSize,
            immediate: immediate
        )
    }

    func handleCameraZoom(currentZoom: CGFloat, zoomDelta: CGFloat) -> CameraZoomResult {
        return updateCameraUseCase.handleZoom(currentZoom: currentZoom, zoomDelta: zoomDelta)
    }

    func handleCameraPan(
        currentPosition: Position,
        panDelta: Position,
        screenSize: CGSize
    ) -> CameraUpdateResult {
        return updateCameraUseCase.handlePan(
            currentPosition: currentPosition,
            panDelta: panDelta,
            courseSize: courseWorldSize,
            screenSize: screenSize
        )
    }
}

// MARK: - GameCenter Integration
extension GameController {
    func authenticateGameCenter() async {
        await gameCenterService.authenticate()
    }

    func loadLeaderboard() async throws -> [LeaderboardEntry] {
        return try await gameCenterService.loadLeaderboard("com.runner.leaderboard.total_score")
    }

    func reportAchievement(_ achievementID: String, progress: Double) async {
        do {
            try await gameCenterService.reportAchievement(achievementID, progress: progress)
        } catch {
            print("❌ Failed to report achievement: \(error)")
        }
    }
}

// MARK: - Game Persistence
extension GameController {
    func startNewGameSession() {
        guard let player = currentPlayer,
              let course = currentCourse else { return }

        let session = GameSession(
            playerName: player.displayName,
            courseName: course.name,
            holeCount: course.holes.count,
            totalPar: course.holes.reduce(0) { $0 + $1.par }
        )

        currentGameSession = session

        do {
            try persistenceService.saveGameSession(session)
            print("📝 Started new game session: \(session.id)")
        } catch {
            print("❌ Failed to save game session: \(error)")
        }
    }

    func updateGameSession(withHoleScore holeScore: HoleScore) {
        guard let session = currentGameSession else { return }

        // Update session with hole completion
        var updatedHoleScores = session.decodedHoleScores
        updatedHoleScores.append(holeScore)

        // Create updated session
        let updatedSession = GameSession(
            id: session.id,
            playerName: session.playerName,
            courseName: session.courseName,
            holeCount: session.holeCount,
            totalStrokes: session.totalStrokes + holeScore.strokes,
            totalPar: session.totalPar,
            startTime: session.startTime,
            endTime: session.endTime,
            isCompleted: session.isCompleted,
            holeScores: updatedHoleScores,
            achievements: session.decodedAchievements
        )

        currentGameSession = updatedSession

        do {
            try persistenceService.saveGameSession(updatedSession)
            print("📝 Updated game session with hole \(holeScore.holeNumber)")
        } catch {
            print("❌ Failed to update game session: \(error)")
        }
    }

    func completeGameSession() {
        guard let session = currentGameSession else { return }

        // Mark session as completed
        let completedSession = GameSession(
            id: session.id,
            playerName: session.playerName,
            courseName: session.courseName,
            holeCount: session.holeCount,
            totalStrokes: session.totalStrokes,
            totalPar: session.totalPar,
            startTime: session.startTime,
            endTime: Date(),
            isCompleted: true,
            holeScores: session.decodedHoleScores,
            achievements: session.decodedAchievements
        )

        currentGameSession = completedSession

        do {
            try persistenceService.saveGameSession(completedSession)
            try persistenceService.updateStatistics(with: completedSession)
            print("🏆 Completed game session: \(completedSession.id)")
            print("📊 Updated player statistics")
        } catch {
            print("❌ Failed to complete game session: \(error)")
        }
    }

    func loadUserPreferences() {
        do {
            let preferences = try persistenceService.loadUserPreferences()
            print("⚙️ Loaded user preferences: \(preferences)")
            // Apply preferences to game configuration if needed
        } catch {
            print("❌ Failed to load user preferences: \(error)")
        }
    }

    func loadPlayerStatistics() {
        do {
            if let stats = try persistenceService.loadPlayerStats() {
                print("📊 Player Statistics:")
                print("   Rounds Played: \(stats.roundsPlayed)")
                print("   Best Score: \(stats.bestScore ?? 0)")
                print("   Total Strokes: \(stats.totalStrokes)")
                print("   Holes in One: \(stats.holesInOne)")
            }
        } catch {
            print("❌ Failed to load player statistics: \(error)")
        }
    }
}

// MARK: - Game State
enum GameState {
    case menu
    case playing
    case paused
    case gameOver
    case leaderboard
}
