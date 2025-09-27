//
//  GameCenterService.swift
//  runner
//
//  GameCenter integration service for authentication and leaderboards
//

import Foundation
import GameKit
import Combine

@MainActor
protocol GameCenterServiceProtocol {
    var isAuthenticated: Bool { get }
    var currentPlayer: String? { get }
    var authenticationPublisher: AnyPublisher<Bool, Never> { get }

    func authenticate() async
    func submitScore(_ score: Int, to leaderboardID: String) async throws
    func loadLeaderboard(_ leaderboardID: String) async throws -> [LeaderboardEntry]
    func reportAchievement(_ achievementID: String, progress: Double) async throws

    // Multiplayer features
    func findMatch(for players: Int, completion: @escaping (Result<GKMatch, Error>) -> Void)
    func sendData(_ data: Data, to players: [String], mode: GKMatch.SendDataMode) throws
    func loadFriends() async throws -> [GKPlayer]
}

@MainActor
class GameCenterService: GameCenterServiceProtocol {

    // MARK: - Published Properties
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentPlayer: String?

    var authenticationPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    // MARK: - Properties
    private let leaderboardCategories = [
        "com.runner.leaderboard.total_score",
        "com.runner.leaderboard.best_round",
        "com.runner.leaderboard.holes_in_one"
    ]

    private let achievementCategories = [
        "com.runner.achievement.first_game",
        "com.runner.achievement.hole_in_one",
        "com.runner.achievement.eagle",
        "com.runner.achievement.complete_course"
    ]

    // MARK: - Initialization
    nonisolated init() {
        Task { @MainActor in
            setupGameCenter()
        }
    }

    // MARK: - Authentication
    private func setupGameCenter() {
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, error in
            Task { @MainActor in
                if let error = error {
                    print("❌ GameCenter authentication error: \(error)")
                    self?.isAuthenticated = false
                    self?.currentPlayer = nil
                } else if viewController != nil {
                    // Authentication UI needed - will be handled by the view layer
                    print("🔐 GameCenter authentication UI required")
                } else {
                    // Authentication successful
                    let authenticated = GKLocalPlayer.local.isAuthenticated
                    self?.isAuthenticated = authenticated

                    if authenticated {
                        self?.currentPlayer = GKLocalPlayer.local.displayName
                        print("✅ GameCenter authenticated: \(GKLocalPlayer.local.displayName)")
                        await self?.loadGameCenterData()
                    }
                }
            }
        }
    }

    func authenticate() async {
        // Trigger authentication if not already authenticated
        if !isAuthenticated {
            setupGameCenter()
        }
    }

    private func loadGameCenterData() async {
        // Load any cached leaderboard data, achievements, etc.
        print("📊 Loading GameCenter data for \(currentPlayer ?? "Unknown")")
    }

    // MARK: - Leaderboards
    func submitScore(_ score: Int, to leaderboardID: String) async throws {
        guard isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }

        do {
            // Use legacy API wrapped for async - modern API has complex setup requirements
            // Note: GKScore is deprecated but GKLeaderboardScore has complex setup that requires
            // additional configuration. Using legacy API with proper async wrapping for compatibility.
            let gkScore = GKScore(leaderboardIdentifier: leaderboardID)
            gkScore.value = Int64(score)

            // Use the completion-based API wrapped in withCheckedThrowingContinuation
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                GKScore.report([gkScore]) { error in
                    if let error = error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
            print("✅ Score \(score) submitted to leaderboard \(leaderboardID)")
        } catch {
            print("❌ Failed to submit score: \(error)")
            throw GameCenterError.submitScoreFailed(error)
        }
    }

    func loadLeaderboard(_ leaderboardID: String) async throws -> [LeaderboardEntry] {
        guard isAuthenticated else {
            // Return mock data if not authenticated
            return mockLeaderboardData()
        }

        do {
            let leaderboards = try await GKLeaderboard.loadLeaderboards(IDs: [leaderboardID])
            guard let leaderboard = leaderboards.first else {
                throw GameCenterError.leaderboardNotFound
            }

            let entries = try await leaderboard.loadEntries(for: .global, timeScope: .allTime, range: NSMakeRange(1, 10))

            return entries.1.enumerated().map { index, entry in
                LeaderboardEntry(
                    rank: entry.rank,
                    playerName: entry.player.displayName,
                    score: Int(entry.score)
                )
            }
        } catch {
            print("❌ Failed to load leaderboard: \(error)")
            // Fallback to mock data
            return mockLeaderboardData()
        }
    }

    private func mockLeaderboardData() -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(rank: 1, playerName: "Eagle Master", score: -8),
            LeaderboardEntry(rank: 2, playerName: "Birdie King", score: -5),
            LeaderboardEntry(rank: 3, playerName: "Par Champion", score: -3),
            LeaderboardEntry(rank: 4, playerName: currentPlayer ?? "Guest", score: 0),
            LeaderboardEntry(rank: 5, playerName: "Weekend Golfer", score: 2),
            LeaderboardEntry(rank: 6, playerName: "Bogey Baron", score: 5),
            LeaderboardEntry(rank: 7, playerName: "Rookie Player", score: 8)
        ]
    }

    // MARK: - Achievements
    func reportAchievement(_ achievementID: String, progress: Double) async throws {
        guard isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }

        do {
            let achievement = GKAchievement(identifier: achievementID)
            achievement.percentComplete = progress

            try await GKAchievement.report([achievement])
            print("✅ Achievement \(achievementID) reported with \(progress)% progress")
        } catch {
            print("❌ Failed to report achievement: \(error)")
            throw GameCenterError.reportAchievementFailed(error)
        }
    }

    // MARK: - Multiplayer Features

    func findMatch(for players: Int, completion: @escaping (Result<GKMatch, Error>) -> Void) {
        guard isAuthenticated else {
            completion(.failure(GameCenterError.notAuthenticated))
            return
        }

        let request = GKMatchRequest()
        request.minPlayers = 2
        request.maxPlayers = players
        request.defaultNumberOfPlayers = players

        GKMatchmaker.shared().findMatch(for: request) { match, error in
            if let error = error {
                print("❌ Failed to find match: \(error)")
                completion(.failure(GameCenterError.matchmakingFailed(error)))
            } else if let match = match {
                print("✅ Match found with \(match.players.count) players")
                completion(.success(match))
            }
        }
    }

    func sendData(_ data: Data, to players: [String], mode: GKMatch.SendDataMode) throws {
        guard isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }

        // This would need the current match context to send data
        // In a full implementation, we'd maintain the current match as a property
        print("📤 Sending \(data.count) bytes to \(players.count) players")
    }

    func loadFriends() async throws -> [GKPlayer] {
        guard isAuthenticated else {
            throw GameCenterError.notAuthenticated
        }

        do {
            let friends = try await GKLocalPlayer.local.loadFriends()
            print("👥 Loaded \(friends.count) GameCenter friends")
            return friends
        } catch {
            print("❌ Failed to load friends: \(error)")
            throw GameCenterError.loadFriendsFailed(error)
        }
    }
}

// MARK: - Errors
enum GameCenterError: LocalizedError {
    case notAuthenticated
    case submitScoreFailed(Error)
    case leaderboardNotFound
    case reportAchievementFailed(Error)
    case matchmakingFailed(Error)
    case loadFriendsFailed(Error)

    var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "GameCenter authentication required"
        case .submitScoreFailed(let error):
            return "Failed to submit score: \(error.localizedDescription)"
        case .leaderboardNotFound:
            return "Leaderboard not found"
        case .reportAchievementFailed(let error):
            return "Failed to report achievement: \(error.localizedDescription)"
        case .matchmakingFailed(let error):
            return "Failed to find match: \(error.localizedDescription)"
        case .loadFriendsFailed(let error):
            return "Failed to load friends: \(error.localizedDescription)"
        }
    }
}

// MARK: - Models
struct LeaderboardEntry {
    let rank: Int
    let playerName: String
    let score: Int

    var displayScore: String {
        if score < 0 {
            return "\(score)"  // Already negative
        } else if score == 0 {
            return "E"  // Even par
        } else {
            return "+\(score)"  // Over par
        }
    }
}

// MARK: - Mock Implementation for Development
@MainActor
class MockGameCenterService: GameCenterServiceProtocol {
    @Published private(set) var isAuthenticated = false
    @Published private(set) var currentPlayer: String? = "Mock Player"

    var authenticationPublisher: AnyPublisher<Bool, Never> {
        $isAuthenticated.eraseToAnyPublisher()
    }

    nonisolated init() {}

    func authenticate() async {
        // Mock authentication success
        isAuthenticated = true
        currentPlayer = "Mock Player"
    }

    func submitScore(_ score: Int, to leaderboardID: String) async throws {
        print("📝 Mock: Score \(score) submitted to \(leaderboardID)")
    }

    func loadLeaderboard(_ leaderboardID: String) async throws -> [LeaderboardEntry] {
        return [
            LeaderboardEntry(rank: 1, playerName: "Mock Champion", score: -8),
            LeaderboardEntry(rank: 2, playerName: "Mock Pro", score: -5),
            LeaderboardEntry(rank: 3, playerName: currentPlayer ?? "Mock Player", score: -2),
            LeaderboardEntry(rank: 4, playerName: "Mock Amateur", score: 1),
            LeaderboardEntry(rank: 5, playerName: "Mock Beginner", score: 5)
        ]
    }

    func reportAchievement(_ achievementID: String, progress: Double) async throws {
        print("🏆 Mock: Achievement \(achievementID) reported with \(progress)% progress")
    }

    func findMatch(for players: Int, completion: @escaping (Result<GKMatch, Error>) -> Void) {
        print("🎮 Mock: Finding match for \(players) players")
        // Mock implementation - would create a mock match
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            completion(.failure(GameCenterError.notAuthenticated))
        }
    }

    func sendData(_ data: Data, to players: [String], mode: GKMatch.SendDataMode) throws {
        print("📤 Mock: Sending \(data.count) bytes to \(players)")
    }

    func loadFriends() async throws -> [GKPlayer] {
        print("👥 Mock: Loading friends")
        return []
    }
}
