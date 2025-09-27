//
//  NetworkService.swift
//  GreenShot
//
//  High-level network service for golf game operations
//

import Foundation
import Combine

// MARK: - Network Service Protocol
protocol NetworkServiceProtocol {
    var isConnected: Bool { get }
    var connectionPublisher: AnyPublisher<NetworkStatus, Never> { get }

    // Authentication
    func authenticate(username: String, password: String) async throws -> AuthenticationResponse
    func refreshToken() async throws -> AuthenticationResponse

    // Leaderboards
    func getLeaderboard(category: LeaderboardCategory, timeframe: TimeFrame) async throws -> [NetworkLeaderboardEntry]
    func submitScore(_ score: Int, category: LeaderboardCategory) async throws -> ScoreSubmissionResponse

    // Multiplayer
    func createMatch(settings: MultiplayerSettings) async throws -> MultiplayerMatch
    func joinMatch(matchId: String) async throws -> MultiplayerMatch
    func getAvailableMatches() async throws -> [MultiplayerMatch]
    func connectToMatch(matchId: String) async throws -> MultiplayerConnection

    // Course sharing
    func uploadCourse(_ course: Course) async throws -> CourseUploadResponse
    func downloadCourse(courseId: String) async throws -> Course
    func getPopularCourses() async throws -> [CourseMetadata]
}

// MARK: - Response Models
struct AuthenticationResponse: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: TimeInterval
    let user: NetworkUser
}

struct NetworkUser: Codable {
    let id: String
    let username: String
    let displayName: String
    let avatar: String?
    let stats: PlayerStats
}

struct PlayerStats: Codable {
    let gamesPlayed: Int
    let bestScore: Int
    let averageScore: Double
    let holesInOne: Int
    let achievements: [String]
}

struct NetworkLeaderboardEntry: Codable {
    let rank: Int
    let playerId: String
    let playerName: String
    let score: Int
    let timestamp: Date
    let courseId: String?
}

struct ScoreSubmissionResponse: Codable {
    let success: Bool
    let newRank: Int?
    let previousBest: Int?
    let achievements: [String]
}

struct MultiplayerMatch: Codable {
    let id: String
    let name: String
    let maxPlayers: Int
    let currentPlayers: Int
    let status: MatchStatus
    let settings: MultiplayerSettings
    let courseId: String
    let createdAt: Date
    let players: [NetworkUser]
}

struct MultiplayerSettings: Codable {
    let maxPlayers: Int
    let courseType: CourseType
    let timeLimit: TimeInterval?
    let allowSpectators: Bool
    let isPrivate: Bool
    let password: String?
}

enum MatchStatus: String, Codable {
    case waiting = "waiting"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum CourseType: String, Codable {
    case generated = "generated"
    case custom = "custom"
    case featured = "featured"
}

enum LeaderboardCategory: String, Codable, CaseIterable {
    case totalScore = "total_score"
    case bestRound = "best_round"
    case holesInOne = "holes_in_one"
    case achievements = "achievements"
}

enum TimeFrame: String, Codable, CaseIterable {
    case daily = "daily"
    case weekly = "weekly"
    case monthly = "monthly"
    case allTime = "all_time"
}

struct CourseUploadResponse: Codable {
    let courseId: String
    let success: Bool
    let url: String?
}

struct CourseMetadata: Codable {
    let id: String
    let name: String
    let description: String
    let authorId: String
    let authorName: String
    let difficulty: Float
    let rating: Float
    let playCount: Int
    let thumbnail: String?
    let createdAt: Date
}

// MARK: - Multiplayer Connection
protocol MultiplayerConnection {
    var isConnected: Bool { get }
    var messagePublisher: AnyPublisher<MultiplayerMessage, Never> { get }

    func sendMessage(_ message: MultiplayerMessage) async throws
    func disconnect()
}

struct MultiplayerMessage: Codable {
    let type: MessageType
    let playerId: String
    let timestamp: Date
    let data: Data

    enum MessageType: String, Codable {
        case playerJoined = "player_joined"
        case playerLeft = "player_left"
        case shotTaken = "shot_taken"
        case holeCompleted = "hole_completed"
        case gameStateChanged = "game_state_changed"
        case chatMessage = "chat_message"
        case matchEnded = "match_ended"
    }
}

// MARK: - Network Service Implementation
class NetworkService: NetworkServiceProtocol {
    private let networkClient: NetworkClientProtocol
    private var authToken: String?
    private var refreshToken: String?

    var isConnected: Bool {
        networkClient.isConnected
    }

    var connectionPublisher: AnyPublisher<NetworkStatus, Never> {
        networkClient.connectionPublisher
    }

    init(networkClient: NetworkClientProtocol) {
        self.networkClient = networkClient
    }

    // MARK: - Authentication
    func authenticate(username: String, password: String) async throws -> AuthenticationResponse {
        let credentials = [
            "username": username,
            "password": password
        ]

        let endpoint = APIEndpoint.authenticate(credentials: credentials)
        let response: AuthenticationResponse = try await networkClient.request(endpoint)

        // Store tokens
        self.authToken = response.accessToken
        self.refreshToken = response.refreshToken

        return response
    }

    func refreshToken() async throws -> AuthenticationResponse {
        guard let refreshToken = refreshToken else {
            throw NetworkError.requestFailed(401, "No refresh token available")
        }

        let endpoint = APIEndpoint.refreshToken(token: refreshToken)
        let response: AuthenticationResponse = try await networkClient.request(endpoint)

        // Update tokens
        self.authToken = response.accessToken
        self.refreshToken = response.refreshToken

        return response
    }

    // MARK: - Leaderboards
    func getLeaderboard(category: LeaderboardCategory, timeframe: TimeFrame) async throws -> [NetworkLeaderboardEntry] {
        let endpoint = APIEndpoint.getLeaderboard(
            category: category.rawValue,
            timeframe: timeframe.rawValue
        )

        struct LeaderboardResponse: Codable {
            let entries: [NetworkLeaderboardEntry]
        }

        let response: LeaderboardResponse = try await networkClient.request(endpoint)
        return response.entries
    }

    func submitScore(_ score: Int, category: LeaderboardCategory) async throws -> ScoreSubmissionResponse {
        guard let token = authToken else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        let endpoint = APIEndpoint.submitScore(
            score: score,
            category: category.rawValue,
            token: token
        )

        return try await networkClient.request(endpoint)
    }

    // MARK: - Multiplayer
    func createMatch(settings: MultiplayerSettings) async throws -> MultiplayerMatch {
        guard let token = authToken else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        let settingsDict = try settings.toDictionary()
        let endpoint = APIEndpoint.createMatch(settings: settingsDict, token: token)

        return try await networkClient.request(endpoint)
    }

    func joinMatch(matchId: String) async throws -> MultiplayerMatch {
        guard let token = authToken else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        let endpoint = APIEndpoint.joinMatch(matchId: matchId, token: token)
        return try await networkClient.request(endpoint)
    }

    func getAvailableMatches() async throws -> [MultiplayerMatch] {
        let endpoint = APIEndpoint(path: "/multiplayer/matches")

        struct MatchesResponse: Codable {
            let matches: [MultiplayerMatch]
        }

        let response: MatchesResponse = try await networkClient.request(endpoint)
        return response.matches
    }

    func connectToMatch(matchId: String) async throws -> MultiplayerConnection {
        let webSocketEndpoint = WebSocketEndpoint.multiplayerMatch(matchId: matchId)
        let webSocketConnection = try await networkClient.establishWebSocket(for: webSocketEndpoint)

        return MultiplayerConnectionImpl(connection: webSocketConnection)
    }

    // MARK: - Course Sharing
    func uploadCourse(_ course: Course) async throws -> CourseUploadResponse {
        guard let token = authToken else {
            throw NetworkError.requestFailed(401, "Authentication required")
        }

        // NOTE: Course serialization requires Course to implement Codable protocol
        // For now, just return a mock response
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate upload
        return CourseUploadResponse(
            courseId: "uploaded_\(UUID().uuidString)",
            success: true,
            url: "https://api.golfgame.com/courses/mock"
        )
    }

    func downloadCourse(courseId: String) async throws -> Course {
        // NOTE: Course deserialization requires Course to implement Codable protocol
        // For now, throw an error
        throw NetworkError.requestFailed(501, "Course download not yet implemented")
    }

    func getPopularCourses() async throws -> [CourseMetadata] {
        let endpoint = APIEndpoint(
            path: "/courses/popular",
            queryParameters: ["limit": "20"]
        )

        struct CoursesResponse: Codable {
            let courses: [CourseMetadata]
        }

        let response: CoursesResponse = try await networkClient.request(endpoint)
        return response.courses
    }
}

// MARK: - Multiplayer Connection Implementation
class MultiplayerConnectionImpl: MultiplayerConnection {
    private let connection: WebSocketConnection
    private let messageSubject = PassthroughSubject<MultiplayerMessage, Never>()
    private var cancellables = Set<AnyCancellable>()

    var isConnected: Bool {
        connection.isConnected
    }

    var messagePublisher: AnyPublisher<MultiplayerMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    init(connection: WebSocketConnection) {
        self.connection = connection

        // Convert incoming data to MultiplayerMessage
        connection.messagePublisher
            .compactMap { data in
                try? JSONDecoder().decode(MultiplayerMessage.self, from: data)
            }
            .sink { [weak self] message in
                self?.messageSubject.send(message)
            }
            .store(in: &cancellables)
    }

    func sendMessage(_ message: MultiplayerMessage) async throws {
        let data = try JSONEncoder().encode(message)
        try await connection.send(data)
    }

    func disconnect() {
        connection.disconnect()
        cancellables.removeAll()
    }
}

// MARK: - Mock Network Service for Development
class MockNetworkService: NetworkServiceProtocol {
    @Published private(set) var isConnected: Bool = true
    private let connectionSubject = CurrentValueSubject<NetworkStatus, Never>(.connected)

    var connectionPublisher: AnyPublisher<NetworkStatus, Never> {
        connectionSubject.eraseToAnyPublisher()
    }

    func authenticate(username: String, password: String) async throws -> AuthenticationResponse {
        // Simulate network delay
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second

        return AuthenticationResponse(
            accessToken: "mock_access_token",
            refreshToken: "mock_refresh_token",
            expiresIn: 3600,
            user: NetworkUser(
                id: "mock_user_id",
                username: username,
                displayName: "Mock Player",
                avatar: nil,
                stats: PlayerStats(
                    gamesPlayed: 42,
                    bestScore: -5,
                    averageScore: 2.1,
                    holesInOne: 3,
                    achievements: ["first_game", "hole_in_one"]
                )
            )
        )
    }

    func refreshToken() async throws -> AuthenticationResponse {
        return try await authenticate(username: "mock", password: "mock")
    }

    func getLeaderboard(category: LeaderboardCategory, timeframe: TimeFrame) async throws -> [NetworkLeaderboardEntry] {
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

        return [
            NetworkLeaderboardEntry(rank: 1, playerId: "player1", playerName: "Champion", score: -8, timestamp: Date(), courseId: "course1"),
            NetworkLeaderboardEntry(rank: 2, playerId: "player2", playerName: "Pro Golfer", score: -5, timestamp: Date(), courseId: "course1"),
            NetworkLeaderboardEntry(rank: 3, playerId: "player3", playerName: "Mock Player", score: -2, timestamp: Date(), courseId: "course1"),
            NetworkLeaderboardEntry(rank: 4, playerId: "player4", playerName: "Amateur", score: 1, timestamp: Date(), courseId: "course1"),
            NetworkLeaderboardEntry(rank: 5, playerId: "player5", playerName: "Beginner", score: 5, timestamp: Date(), courseId: "course1")
        ]
    }

    func submitScore(_ score: Int, category: LeaderboardCategory) async throws -> ScoreSubmissionResponse {
        try await Task.sleep(nanoseconds: 500_000_000)

        return ScoreSubmissionResponse(
            success: true,
            newRank: 3,
            previousBest: score + 2,
            achievements: score <= -5 ? ["eagle_master"] : []
        )
    }

    func createMatch(settings: MultiplayerSettings) async throws -> MultiplayerMatch {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        return MultiplayerMatch(
            id: "mock_match_\(UUID().uuidString)",
            name: "Mock Match",
            maxPlayers: settings.maxPlayers,
            currentPlayers: 1,
            status: .waiting,
            settings: settings,
            courseId: "mock_course",
            createdAt: Date(),
            players: []
        )
    }

    func joinMatch(matchId: String) async throws -> MultiplayerMatch {
        try await Task.sleep(nanoseconds: 500_000_000)

        return MultiplayerMatch(
            id: matchId,
            name: "Joined Match",
            maxPlayers: 4,
            currentPlayers: 2,
            status: .waiting,
            settings: MultiplayerSettings(
                maxPlayers: 4,
                courseType: .generated,
                timeLimit: nil,
                allowSpectators: true,
                isPrivate: false,
                password: nil
            ),
            courseId: "mock_course",
            createdAt: Date(),
            players: []
        )
    }

    func getAvailableMatches() async throws -> [MultiplayerMatch] {
        try await Task.sleep(nanoseconds: 500_000_000)
        return []
    }

    func connectToMatch(matchId: String) async throws -> MultiplayerConnection {
        return MockMultiplayerConnection()
    }

    func uploadCourse(_ course: Course) async throws -> CourseUploadResponse {
        try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds

        return CourseUploadResponse(
            courseId: "uploaded_\(UUID().uuidString)",
            success: true,
            url: "https://api.golfgame.com/courses/uploaded_course"
        )
    }

    func downloadCourse(courseId: String) async throws -> Course {
        try await Task.sleep(nanoseconds: 1_000_000_000)

        // Return a mock course - this would need proper Course construction
        throw NetworkError.requestFailed(404, "Course not found")
    }

    func getPopularCourses() async throws -> [CourseMetadata] {
        try await Task.sleep(nanoseconds: 500_000_000)

        return [
            CourseMetadata(
                id: "popular1",
                name: "Augusta Replica",
                description: "A challenging 18-hole course inspired by Augusta National",
                authorId: "author1",
                authorName: "Course Master",
                difficulty: 0.8,
                rating: 4.7,
                playCount: 15420,
                thumbnail: nil,
                createdAt: Date()
            ),
            CourseMetadata(
                id: "popular2",
                name: "Desert Challenge",
                description: "Navigate sand traps and rocky terrain",
                authorId: "author2",
                authorName: "Desert Fox",
                difficulty: 0.6,
                rating: 4.3,
                playCount: 8930,
                thumbnail: nil,
                createdAt: Date()
            )
        ]
    }
}

// MARK: - Mock Multiplayer Connection
class MockMultiplayerConnection: MultiplayerConnection {
    @Published private(set) var isConnected: Bool = true
    private let messageSubject = PassthroughSubject<MultiplayerMessage, Never>()

    var messagePublisher: AnyPublisher<MultiplayerMessage, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    func sendMessage(_ message: MultiplayerMessage) async throws {
        // Echo the message back for testing
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        messageSubject.send(message)
    }

    func disconnect() {
        isConnected = false
    }
}

// MARK: - Helper Extensions
extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
        return dictionary ?? [:]
    }
}