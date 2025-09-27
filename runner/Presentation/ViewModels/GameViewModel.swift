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
    @Published var currentPar: Int = 3
    @Published var currentStrokes: Int = 0
    @Published var currentScore: Score?
    @Published var showSettings = false
    @Published var showLeaderboard = false
    @Published var showHoleDebug = false

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

        // Observe course changes
        gameController.$currentCourse
            .compactMap { $0?.currentHole }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] hole in
                self?.currentHole = hole.number
                self?.currentPar = hole.par
                self?.updateCurrentScore()
            }
            .store(in: &cancellables)

    }

    private func updateCurrentScore() {
        if currentStrokes > 0 {
            currentScore = Score(strokes: currentStrokes, par: currentPar)
        } else {
            currentScore = nil
        }
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
        "Hole \(currentHole) - Par \(currentPar)"
    }

    var strokeText: String {
        currentStrokes == 1 ? "1 Stroke" : "\(currentStrokes) Strokes"
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

    var currentCourse: Course? {
        gameController.currentCourse
    }
}