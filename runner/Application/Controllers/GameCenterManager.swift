//
//  GameCenterManager.swift
//  runner
//
//  Comprehensive GameCenter management with automatic achievement tracking
//

import Foundation
import GameKit
import Combine

class GameCenterManager: ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentPlayer: String?
    @Published private(set) var leaderboardEntries: [LeaderboardEntry] = []
    @Published private(set) var isLoadingLeaderboard = false

    // MARK: - Dependencies
    private let gameCenterService: GameCenterServiceProtocol
    private let persistenceService: PersistenceServiceProtocol
    private let eventBus: EventBusProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Achievement Tracking
    private var achievementTracker: [String: Double] = [:]

    init(
        gameCenterService: GameCenterServiceProtocol,
        persistenceService: PersistenceServiceProtocol,
        eventBus: EventBusProtocol
    ) {
        self.gameCenterService = gameCenterService
        self.persistenceService = persistenceService
        self.eventBus = eventBus

        setupSubscriptions()
        setupAchievementTracking()
    }

    // MARK: - Setup

    private func setupSubscriptions() {
        // Subscribe to GameCenter authentication changes
        gameCenterService.authenticationPublisher
            .receive(on: DispatchQueue.main)
            .assign(to: \.isAuthenticated, on: self)
            .store(in: &cancellables)

        // Listen for game events to trigger GameCenter actions
        setupGameEventListeners()
    }

    private func setupGameEventListeners() {
        // Listen for game completion to submit scores
        NotificationCenter.default.publisher(for: NSNotification.Name("GameEndedEvent"))
            .sink { [weak self] notification in
                if let score = notification.userInfo?["finalScore"] as? Score {
                    Task {
                        await self?.handleGameCompleted(score: score)
                    }
                }
            }
            .store(in: &cancellables)

        // Listen for hole completions to track achievements
        NotificationCenter.default.publisher(for: NSNotification.Name("HoleCompletedEvent"))
            .sink { [weak self] notification in
                if let hole = notification.userInfo?["hole"] as? Hole,
                   let score = notification.userInfo?["score"] as? Score {
                    Task {
                        await self?.handleHoleCompleted(hole: hole, score: score)
                    }
                }
            }
            .store(in: &cancellables)

        // Listen for game start to reset session tracking
        NotificationCenter.default.publisher(for: NSNotification.Name("GameStartedEvent"))
            .sink { [weak self] _ in
                self?.handleGameStarted()
            }
            .store(in: &cancellables)
    }

    private func setupAchievementTracking() {
        // Initialize achievement progress tracking
        achievementTracker = [
            "com.runner.achievement.first_game": 0.0,
            "com.runner.achievement.hole_in_one": 0.0,
            "com.runner.achievement.eagle": 0.0,
            "com.runner.achievement.complete_course": 0.0,
            "com.runner.achievement.birdie_streak": 0.0,
            "com.runner.achievement.par_round": 0.0,
            "com.runner.achievement.under_par": 0.0,
            "com.runner.achievement.course_master": 0.0
        ]
    }

    // MARK: - Game Event Handlers

    private func handleGameStarted() {
        print("🎮 GameCenter: Game started, resetting session tracking")
        // Reset session-specific achievement tracking
    }

    private func handleGameCompleted(score: Score) async {
        guard isAuthenticated else { return }

        do {
            // Submit total score to main leaderboard
            let relativeScore = score.strokes - score.par
            try await gameCenterService.submitScore(relativeScore, to: "com.runner.leaderboard.total_score")

            // Check and report course completion achievements
            await checkCourseCompletionAchievements(score: score)

            // Load updated leaderboard
            await loadLeaderboard()

        } catch {
            print("❌ Failed to handle game completion: \(error)")
        }
    }

    private func handleHoleCompleted(hole: Hole, score: Score) async {
        guard isAuthenticated else { return }

        let relativeToPar = score.strokes - score.par

        // Check for specific achievements
        await checkHoleAchievements(hole: hole, relativeToPar: relativeToPar)
    }

    // MARK: - Achievement Checking

    private func checkHoleAchievements(hole: Hole, relativeToPar: Int) async {
        do {
            // Hole in one achievement
            if relativeToPar <= -hole.par + 1 {  // Hole in one (1 stroke regardless of par)
                try await reportAchievementProgress("com.runner.achievement.hole_in_one", progress: 100.0)
            }

            // Eagle achievement (-2 or better)
            if relativeToPar <= -2 {
                let currentProgress = achievementTracker["com.runner.achievement.eagle"] ?? 0.0
                let newProgress = min(100.0, currentProgress + 25.0) // 4 eagles = 100%
                try await reportAchievementProgress("com.runner.achievement.eagle", progress: newProgress)
            }

        } catch {
            print("❌ Failed to check hole achievements: \(error)")
        }
    }

    private func checkCourseCompletionAchievements(score: Score) async {
        do {
            // First game completion
            let stats = try persistenceService.loadPlayerStats()
            if stats?.roundsPlayed == 1 {
                try await reportAchievementProgress("com.runner.achievement.first_game", progress: 100.0)
            }

            // Complete course achievement
            try await reportAchievementProgress("com.runner.achievement.complete_course", progress: 100.0)

            // Par or better round
            if score.strokes <= score.par {
                try await reportAchievementProgress("com.runner.achievement.par_round", progress: 100.0)
            }

            // Under par round
            if score.strokes < score.par {
                try await reportAchievementProgress("com.runner.achievement.under_par", progress: 100.0)
            }

            // Course master (multiple course completions)
            if let roundsPlayed = stats?.roundsPlayed, roundsPlayed >= 10 {
                let progress = min(100.0, Double(roundsPlayed) * 10.0) // 10 rounds = 100%
                try await reportAchievementProgress("com.runner.achievement.course_master", progress: progress)
            }

        } catch {
            print("❌ Failed to check course completion achievements: \(error)")
        }
    }

    private func reportAchievementProgress(_ achievementID: String, progress: Double) async throws {
        let currentProgress = achievementTracker[achievementID] ?? 0.0

        // Only report if progress increased
        if progress > currentProgress {
            achievementTracker[achievementID] = progress
            try await gameCenterService.reportAchievement(achievementID, progress: progress)

            if progress >= 100.0 {
                print("🏆 Achievement unlocked: \(achievementID)")
            }
        }
    }

    // MARK: - Public Methods

    func authenticate() async {
        await gameCenterService.authenticate()

        // Load initial data after authentication
        if isAuthenticated {
            await loadLeaderboard()
        }
    }

    func loadLeaderboard() async {
        isLoadingLeaderboard = true

        do {
            let entries = try await gameCenterService.loadLeaderboard("com.runner.leaderboard.total_score")

            await MainActor.run {
                self.leaderboardEntries = entries
                self.isLoadingLeaderboard = false
            }
        } catch {
            print("❌ Failed to load leaderboard: \(error)")
            await MainActor.run {
                self.isLoadingLeaderboard = false
            }
        }
    }

    func submitScore(_ score: Int, category: GameCenterLeaderboardCategory = .totalScore) async {
        do {
            try await gameCenterService.submitScore(score, to: category.identifier)
            await loadLeaderboard()
        } catch {
            print("❌ Failed to submit score: \(error)")
        }
    }

    func findMultiplayerMatch(playerCount: Int) {
        gameCenterService.findMatch(for: playerCount) { result in
            switch result {
            case .success(let match):
                print("✅ Found multiplayer match with \(match.players.count) players")
                // Handle match setup

            case .failure(let error):
                print("❌ Failed to find match: \(error)")
            }
        }
    }
}

// MARK: - Supporting Types

enum GameCenterLeaderboardCategory {
    case totalScore
    case bestRound
    case holesInOne

    var identifier: String {
        switch self {
        case .totalScore:
            return "com.runner.leaderboard.total_score"
        case .bestRound:
            return "com.runner.leaderboard.best_round"
        case .holesInOne:
            return "com.runner.leaderboard.holes_in_one"
        }
    }
}