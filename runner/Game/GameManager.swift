//
//  GameManager.swift
//  runner
//
//  DEPRECATED: This class has been replaced by GameController
//  All functionality has been moved to GameController with proper dependency injection
//

import Foundation
import SwiftData
import GameKit
import Combine

@available(*, deprecated, message: "Use GameController instead. This class will be removed in a future version.")
@MainActor
class GameManager: ObservableObject {
    // MARK: - Published Properties
    @Published var currentPlayer: String?
    @Published var isAuthenticated = false
    @Published var gameState: GameState = .menu
    @Published var totalScore: Int = 0

    // MARK: - Game State
    enum GameState {
        case menu
        case playing
        case paused
        case gameOver
        case leaderboard
    }

    // MARK: - Properties
    private var cancellables = Set<AnyCancellable>()
    private var modelContext: ModelContext?

    // MARK: - Initialization
    init() {
        setupGameCenter()
    }

    // MARK: - Game Center
    private func setupGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { viewController, error in
            if viewController != nil {
                // Present authentication view controller
                // This will be handled by the view
            } else if let error = error {
                print("Game Center authentication error: \(error)")
                self.isAuthenticated = false
            } else {
                // Authentication successful
                self.isAuthenticated = GKLocalPlayer.local.isAuthenticated
                if self.isAuthenticated {
                    self.loadPlayerData()
                }
            }
        }
    }

    private func loadPlayerData() {
        self.currentPlayer = GKLocalPlayer.local.displayName
    }

    // MARK: - Game Management
    func startNewGame() {
        totalScore = 0
        gameState = .playing
    }

    func pauseGame() {
        gameState = .paused
    }

    func resumeGame() {
        gameState = .playing
    }

    func endGame() {
        submitToLeaderboard()
        gameState = .gameOver
    }

    // MARK: - Leaderboards
    private func submitToLeaderboard() {
        guard isAuthenticated else { return }

        // Simple implementation for now - will be enhanced later with proper GameKit integration
        print("Score submitted: \(totalScore)")
    }

    @available(*, deprecated, message: "Use GameController.loadLeaderboard() instead")
    func loadLeaderboard(completion: @escaping ([Any]) -> Void) {
        // Deprecated - use GameController instead
        completion([])
    }
}