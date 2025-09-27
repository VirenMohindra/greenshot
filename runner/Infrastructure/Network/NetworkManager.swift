//
//  NetworkManager.swift
//  runner
//
//  Network manager that coordinates between NetworkService and EventBus
//

import Foundation
import Combine

// MARK: - Network Manager Protocol
protocol NetworkManagerProtocol {
    var isAuthenticated: Bool { get }
    var currentUser: NetworkUser? { get }
    var isConnected: Bool { get }

    // Authentication
    func signIn(username: String, password: String) async throws
    func signOut()

    // Leaderboards
    func submitScore(_ score: Int, category: LeaderboardCategory) async throws
    func refreshLeaderboards() async throws

    // Multiplayer
    func createMultiplayerMatch(settings: MultiplayerSettings) async throws -> String
    func joinMultiplayerMatch(matchId: String) async throws
    func disconnectFromMatch()

    // Course sharing
    func uploadCourse(_ course: Course) async throws -> String
    func downloadPopularCourses() async throws -> [CourseMetadata]
}

// MARK: - Network Manager Implementation
class NetworkManager: NetworkManagerProtocol, ObservableObject {

    // MARK: - Published Properties
    @Published private(set) var isAuthenticated: Bool = false
    @Published private(set) var currentUser: NetworkUser?
    @Published private(set) var isConnected: Bool = false
    @Published private(set) var currentMatch: MultiplayerMatch?
    @Published private(set) var networkError: NetworkError?

    // MARK: - Private Properties
    private let networkService: NetworkServiceProtocol
    private let eventBus: EventBusProtocol
    private var cancellables = Set<AnyCancellable>()
    private var multiplayerConnection: MultiplayerConnection?

    // MARK: - Initialization
    init(networkService: NetworkServiceProtocol, eventBus: EventBusProtocol) {
        self.networkService = networkService
        self.eventBus = eventBus

        setupNetworkSubscriptions()
        setupEventBusIntegration()
    }

    // MARK: - Setup
    private func setupNetworkSubscriptions() {
        // Monitor network connection status
        networkService.connectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.isConnected = status.isConnected

                // Publish network connection events
                self?.eventBus.publish(NetworkConnectionChangedEvent(isConnected: status.isConnected))

                if case .error(let errorMessage) = status {
                    self?.networkError = NetworkError.requestFailed(0, errorMessage)
                }
            }
            .store(in: &cancellables)
    }

    private func setupEventBusIntegration() {
        // Listen for game events that should be sent to multiplayer
        if let eventBus = eventBus as? EventBus {
            // Listen for shot events in multiplayer matches
            eventBus.shotTaken
                .filter { [weak self] _ in self?.currentMatch != nil }
                .sink { [weak self] shotData in
                    Task {
                        await self?.sendMultiplayerMessage(.shotTaken, data: shotData)
                    }
                }
                .store(in: &cancellables)

            // Listen for hole completion events
            eventBus.holeCompleted
                .filter { [weak self] _ in self?.currentMatch != nil }
                .sink { [weak self] holeData in
                    Task {
                        await self?.sendMultiplayerMessage(.holeCompleted, data: holeData)
                    }
                }
                .store(in: &cancellables)
        }
    }

    // MARK: - Authentication
    func signIn(username: String, password: String) async throws {
        do {
            let response = try await networkService.authenticate(username: username, password: password)

            await MainActor.run {
                self.isAuthenticated = true
                self.currentUser = response.user
                self.networkError = nil
            }

            // Clear any previous authentication errors
            print("✅ Successfully authenticated user: \(response.user.displayName)")

        } catch {
            await MainActor.run {
                self.isAuthenticated = false
                self.currentUser = nil
                self.networkError = error as? NetworkError ?? NetworkError.unknown(error)
            }
            throw error
        }
    }

    func signOut() {
        // Disconnect from any active multiplayer match
        disconnectFromMatch()

        // Clear authentication state
        isAuthenticated = false
        currentUser = nil
        networkError = nil

        print("🔐 User signed out")
    }

    // MARK: - Leaderboards
    func submitScore(_ score: Int, category: LeaderboardCategory) async throws {
        guard isAuthenticated else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        do {
            let response = try await networkService.submitScore(score, category: category)

            if response.success {
                print("✅ Score submitted successfully. New rank: \(response.newRank ?? 0)")

                // Publish achievement events for any new achievements
                for achievementId in response.achievements {
                    // Create Achievement using existing constructor
                    let achievement = Achievement(
                        title: achievementId.capitalized,
                        description: "Achievement unlocked!",
                        icon: "trophy"
                    )
                    eventBus.publish(AchievementUnlockedEvent(achievement: achievement))
                }
            }

        } catch {
            print("❌ Failed to submit score: \(error)")
            throw error
        }
    }

    func refreshLeaderboards() async throws {
        let leaderboardData = try await networkService.getLeaderboard(
            category: .totalScore,
            timeframe: .allTime
        )

        print("📊 Refreshed leaderboard with \(leaderboardData.count) entries")
    }

    // MARK: - Multiplayer
    func createMultiplayerMatch(settings: MultiplayerSettings) async throws -> String {
        guard isAuthenticated else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        let match = try await networkService.createMatch(settings: settings)

        await MainActor.run {
            self.currentMatch = match
        }

        print("🎮 Created multiplayer match: \(match.id)")
        return match.id
    }

    func joinMultiplayerMatch(matchId: String) async throws {
        guard isAuthenticated else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        // Join the match
        let match = try await networkService.joinMatch(matchId: matchId)

        // Establish WebSocket connection
        let connection = try await networkService.connectToMatch(matchId: matchId)

        await MainActor.run {
            self.currentMatch = match
            self.multiplayerConnection = connection
        }

        // Listen for multiplayer messages
        setupMultiplayerMessageHandling()

        print("🎮 Joined multiplayer match: \(matchId)")
    }

    func disconnectFromMatch() {
        multiplayerConnection?.disconnect()
        multiplayerConnection = nil
        currentMatch = nil

        print("🎮 Disconnected from multiplayer match")
    }

    private func setupMultiplayerMessageHandling() {
        multiplayerConnection?.messagePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] message in
                self?.handleMultiplayerMessage(message)
            }
            .store(in: &cancellables)
    }

    private func handleMultiplayerMessage(_ message: MultiplayerMessage) {
        switch message.type {
        case .playerJoined:
            print("👋 Player joined the match")

        case .playerLeft:
            print("👋 Player left the match")

        case .shotTaken:
            print("🏌️ Player took a shot")
            // Could trigger visual effects or UI updates

        case .holeCompleted:
            print("⛳ Player completed a hole")

        case .gameStateChanged:
            print("🎮 Game state changed")

        case .chatMessage:
            print("💬 Chat message received")

        case .matchEnded:
            print("🏁 Match ended")
            disconnectFromMatch()
        }
    }

    private func sendMultiplayerMessage(_ type: MultiplayerMessage.MessageType, data: Any) async {
        guard let connection = multiplayerConnection,
              let currentUser = currentUser else { return }

        do {
            let messageData = try JSONSerialization.data(withJSONObject: data)
            let message = MultiplayerMessage(
                type: type,
                playerId: currentUser.id,
                timestamp: Date(),
                data: messageData
            )

            try await connection.sendMessage(message)
        } catch {
            print("❌ Failed to send multiplayer message: \(error)")
        }
    }

    // MARK: - Course Sharing
    func uploadCourse(_ course: Course) async throws -> String {
        guard isAuthenticated else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        let response = try await networkService.uploadCourse(course)

        if response.success {
            print("✅ Course uploaded successfully: \(response.courseId)")
            return response.courseId
        } else {
            throw NetworkError.requestFailed(500, "Course upload failed")
        }
    }

    func downloadPopularCourses() async throws -> [CourseMetadata] {
        let courses = try await networkService.getPopularCourses()
        print("📥 Downloaded \(courses.count) popular courses")
        return courses
    }
}