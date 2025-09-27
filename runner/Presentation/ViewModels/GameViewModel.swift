//
//  GameViewModel.swift
//  runner
//
//  View model for game state and reactive UI updates
//

import Foundation
import SwiftUI
import Combine

@MainActor
class GameViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var gameState: GameState = .menu
    @Published var currentHole: Int = 1
    @Published var currentHoleIndex: Int = 0
    @Published var currentPar: Int = 3
    @Published var currentStrokes: Int = 0
    @Published var currentScore: Score?
    @Published var currentCourse: Course?
    @Published var totalScore: Int = 0
    @Published var totalStrokes: Int = 0
    @Published var totalPar: Int = 0
    @Published var completedHoles: Int = 0
    @Published var showSettings = false
    @Published var showLeaderboard = false
    @Published var showHoleDebug = false

    // Celebration and progression
    @Published var isCelebrationVisible = false
    @Published var celebrationText = ""
    @Published var celebrationLevel: CelebrationLevel = .none
    @Published var showHoleProgressionMessage = false
    @Published var holeProgressionText = ""

    // Camera and interaction state
    @Published var currentZoom: CGFloat = 0.6
    @Published var cameraPosition: Position = .zero

    // MARK: - Game Controller
    private let gameController: GameController
    private var cancellables = Set<AnyCancellable>()

    init(gameController: GameController) {
        self.gameController = gameController
        setupBindings()
    }

    private func setupBindings() {
        // Observe game controller state changes
        gameController.$gameState
            .receive(on: DispatchQueue.main)
            .assign(to: \.gameState, on: self)
            .store(in: &cancellables)

        gameController.$currentStrokes
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentStrokes, on: self)
            .store(in: &cancellables)

        gameController.$currentCourse
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentCourse, on: self)
            .store(in: &cancellables)

        gameController.$currentPlayer
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateTotalScore()
            }
            .store(in: &cancellables)

        // Observe course changes and hole progression
        gameController.$currentCourse
            .compactMap { $0?.currentHole }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hole in
                let previousHole = self?.currentHole
                self?.currentHole = hole.number
                self?.currentHoleIndex = hole.number - 1  // Convert to 0-based index
                self?.currentPar = hole.par
                self?.updateCurrentScore()

                // Show progression message if we moved to a new hole
                if let previous = previousHole, previous != hole.number && previous > 0 {
                    self?.showHoleProgression(fromHole: previous, toHole: hole.number)
                }
            }
            .store(in: &cancellables)

        // Observe celebrations
        gameController.$lastCompletedScore
            .compactMap { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] score in
                guard let self = self else { return }
                let level = self.gameController.lastCelebrationLevel
                if level.shouldShowMessage {
                    self.showCelebration(for: score, level: level)
                }
                // Update total score when hole is completed
                self.updateTotalScore()
            }
            .store(in: &cancellables)

    }

    private func updateCurrentScore() {
        if currentStrokes > 0 {
            currentScore = Score(strokes: currentStrokes, par: currentPar)
        } else {
            currentScore = nil
        }
        updateTotalScore()
    }

    private func updateTotalScore() {
        guard let player = gameController.currentPlayer,
              let round = player.currentRound else {
            totalScore = 0
            totalStrokes = 0
            totalPar = 0
            completedHoles = 0
            return
        }

        totalStrokes = round.totalStrokes
        totalPar = round.totalPar
        totalScore = round.totalScore // This is strokes relative to par (+ or -)
        completedHoles = round.completedHoles.count
    }
}

// MARK: - Game Actions
extension GameViewModel {
    func startNewGame() {
        DispatchQueue.main.async {
            self.gameController.startNewGame(playerName: "Player")
        }
    }

    func pauseGame() {
        gameController.pauseGame()
    }

    func resumeGame() {
        gameController.resumeGame()
    }

    func resetBallToTee() {
        gameController.resetBallToTee()
    }
}

// MARK: - UI State
extension GameViewModel {
    var progressText: String {
        guard let course = currentCourse else { return "Hole \(currentHole) - Par \(currentPar)" }
        return "Hole \(currentHole) of \(course.totalHoles) - Par \(currentPar)"
    }

    var strokeText: String {
        currentStrokes == 1 ? "1 Stroke" : "\(currentStrokes) Strokes"
    }

    var totalScoreText: String {
        if totalScore == 0 {
            return "E"  // Even par
        } else if totalScore > 0 {
            return "+\(totalScore)"  // Over par
        } else {
            return "\(totalScore)"  // Under par (already has negative sign)
        }
    }

    var roundProgressText: String {
        guard let course = currentCourse else { return "" }
        return "\(currentHole)/\(course.totalHoles) Holes"
    }

    var canPlay: Bool {
        gameState == .playing
    }

    var isPaused: Bool {
        gameState == .paused
    }

    var isGameOver: Bool {
        gameState == .gameOver
    }
}

// MARK: - Camera Management
extension GameViewModel {
    func updateCameraPosition(_ position: Position) {
        cameraPosition = position
    }

    func updateZoom(_ zoom: CGFloat) {
        currentZoom = zoom
    }

    func focusCameraOnBall(screenSize: CGSize) {
        let result = gameController.updateCameraForBall(
            currentCameraPosition: cameraPosition,
            screenSize: screenSize
        )

        if result.shouldUpdate,
           case .update(let newPosition, _, _) = result {
            updateCameraPosition(newPosition)
        }
    }
}

// MARK: - Settings
extension GameViewModel {
    func openSettings() {
        showSettings = true
    }

    func closeSettings() {
        showSettings = false
    }

    func openLeaderboard() {
        showLeaderboard = true
    }

    func closeLeaderboard() {
        showLeaderboard = false
    }

    func openHoleDebug() {
        showHoleDebug = true
    }

    func closeHoleDebug() {
        showHoleDebug = false
    }
}

// MARK: - Celebration and Progression
extension GameViewModel {
    func showCelebration(for score: Score, level: CelebrationLevel) {
        celebrationText = score.celebrationText
        celebrationLevel = level
        isCelebrationVisible = true

        // Auto-hide celebration after duration
        DispatchQueue.main.asyncAfter(deadline: .now() + level.duration) {
            self.hideCelebration()
        }
    }

    func hideCelebration() {
        isCelebrationVisible = false
    }

    private func showHoleProgression(fromHole: Int, toHole: Int) {
        guard let course = currentCourse else { return }

        holeProgressionText = "Moving to Hole \(toHole) of \(course.totalHoles)"
        showHoleProgressionMessage = true

        // Auto-hide progression message
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.hideHoleProgression()
        }
    }

    func hideHoleProgression() {
        showHoleProgressionMessage = false
    }
}