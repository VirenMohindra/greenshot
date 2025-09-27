//
//  GameController.swift
//  runner
//
//  Main game coordinator managing all use cases and game state
//

import Foundation
import Combine

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

    // MARK: - Use Cases
    private let takeShotUseCase: TakeShotUseCaseProtocol
    private let completeHoleUseCase: CompleteHoleUseCaseProtocol
    private let navigateHolesUseCase: NavigateHolesUseCaseProtocol
    private let updateCameraUseCase: UpdateCameraUseCaseProtocol

    // MARK: - Services
    private let holeGenerationService: HoleGenerationServiceProtocol

    // MARK: - Game State
    private let courseWorldSize = CGSize(width: 800, height: 1600)
    private var isCurrentHoleCompleted = false

    init(
        takeShotUseCase: TakeShotUseCaseProtocol,
        completeHoleUseCase: CompleteHoleUseCaseProtocol,
        navigateHolesUseCase: NavigateHolesUseCaseProtocol,
        updateCameraUseCase: UpdateCameraUseCaseProtocol,
        holeGenerationService: HoleGenerationServiceProtocol
    ) {
        self.takeShotUseCase = takeShotUseCase
        self.completeHoleUseCase = completeHoleUseCase
        self.navigateHolesUseCase = navigateHolesUseCase
        self.updateCameraUseCase = updateCameraUseCase
        self.holeGenerationService = holeGenerationService
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

        case .failure(let error):
            print("❌ Failed to start game: \(error)")
        }
    }

    func pauseGame() {
        gameState = .paused
    }

    func resumeGame() {
        gameState = .playing
    }

    func endGame() {
        guard let course = currentCourse,
              let player = currentPlayer else { return }

        let result = navigateHolesUseCase.completeRound(course: course, player: player)

        switch result {
        case .success(let finalScore, _, _, _):
            print("🏆 Game completed with score: \(finalScore)")
            gameState = .gameOver

        case .failure(let error):
            print("❌ Failed to end game: \(error)")
        }
    }
}

// MARK: - Shot Management
extension GameController {
    func takeShot(dragStart: Position, dragEnd: Position, power: CGFloat) {
        guard let ball = golfBall,
              let hole = currentCourse?.currentHole,
              gameState == .playing else { return }

        let result = takeShotUseCase.executeShot(
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

            // Notify scene to apply physics impulse
            NotificationCenter.default.post(
                name: NSNotification.Name("ShotTaken"),
                object: nil,
                userInfo: ["impulse": impulse]
            )
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
              let player = currentPlayer,
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
        case .success(let hole, let progress, let isLastHole):
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

            // Notify scene of game state change
            NotificationCenter.default.post(name: NSNotification.Name("GameStateChanged"), object: nil)
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

// MARK: - Game State
enum GameState {
    case menu
    case playing
    case paused
    case gameOver
    case leaderboard
}
