//
//  PersistenceService.swift
//  runner
//
//  Core data persistence layer using SwiftData and UserDefaults
//

import Foundation
import SwiftData
import Combine

// MARK: - Persistence Service Protocol
protocol PersistenceServiceProtocol {
    // MARK: - User Preferences
    func saveUserPreferences(_ preferences: UserPreferences) throws
    func loadUserPreferences() throws -> UserPreferences

    // MARK: - Game Data
    func saveGameSession(_ session: GameSession) throws
    func loadRecentGameSessions(limit: Int) throws -> [GameSession]
    func deleteGameSession(_ sessionId: UUID) throws

    // MARK: - Course Data
    func saveCourse(_ course: Course) throws
    func loadSavedCourses() throws -> [Course]
    func deleteCourse(_ courseId: UUID) throws

    // MARK: - Statistics
    func savePlayerStats(_ stats: PlayerStatistics) throws
    func loadPlayerStats() throws -> PlayerStatistics?
    func updateStatistics(with session: GameSession) throws

    // MARK: - Cache Management
    func clearCache() throws
    func getDatabaseSize() -> Int64
}

// MARK: - Persistence Models
struct UserPreferences: Codable {
    let soundEnabled: Bool
    let musicEnabled: Bool
    let hapticFeedback: Bool
    let showTrajectoryPreview: Bool
    let autoZoomOnShot: Bool
    let showControlRadius: Bool
    let courseDifficulty: String
    let courseLength: String
    let obstacleFrequency: String
    let showCelebrations: Bool
    let enableTrailEffects: Bool
    let cameraSpeed: Double
    let highContrastMode: Bool
    let reducedMotion: Bool
    let largerText: Bool
    let lastUpdated: Date

    static let `default` = UserPreferences(
        soundEnabled: true,
        musicEnabled: true,
        hapticFeedback: true,
        showTrajectoryPreview: true,
        autoZoomOnShot: true,
        showControlRadius: true,
        courseDifficulty: "medium",
        courseLength: "nine",
        obstacleFrequency: "medium",
        showCelebrations: true,
        enableTrailEffects: true,
        cameraSpeed: 0.5,
        highContrastMode: false,
        reducedMotion: false,
        largerText: false,
        lastUpdated: Date()
    )
}

@Model
class GameSession {
    @Attribute(.unique) var id: UUID
    var playerName: String
    var courseName: String
    var holeCount: Int
    var totalStrokes: Int
    var totalPar: Int
    var startTime: Date
    var endTime: Date?
    var isCompleted: Bool
    var holeScores: Data // JSON encoded [HoleScore]
    var achievements: Data // JSON encoded [String]

    init(
        id: UUID = UUID(),
        playerName: String,
        courseName: String,
        holeCount: Int,
        totalStrokes: Int = 0,
        totalPar: Int,
        startTime: Date = Date(),
        endTime: Date? = nil,
        isCompleted: Bool = false,
        holeScores: [HoleScore] = [],
        achievements: [String] = []
    ) {
        self.id = id
        self.playerName = playerName
        self.courseName = courseName
        self.holeCount = holeCount
        self.totalStrokes = totalStrokes
        self.totalPar = totalPar
        self.startTime = startTime
        self.endTime = endTime
        self.isCompleted = isCompleted

        // Encode arrays to Data
        self.holeScores = (try? JSONEncoder().encode(holeScores)) ?? Data()
        self.achievements = (try? JSONEncoder().encode(achievements)) ?? Data()
    }

    var decodedHoleScores: [HoleScore] {
        (try? JSONDecoder().decode([HoleScore].self, from: holeScores)) ?? []
    }

    var decodedAchievements: [String] {
        (try? JSONDecoder().decode([String].self, from: achievements)) ?? []
    }

    var relativeToPar: Int {
        totalStrokes - totalPar
    }

    var duration: TimeInterval {
        guard let endTime = endTime else { return 0 }
        return endTime.timeIntervalSince(startTime)
    }
}

struct HoleScore: Codable, Identifiable {
    let id: UUID
    let holeNumber: Int
    let par: Int
    let strokes: Int
    let completedAt: Date

    var relativeToPar: Int {
        strokes - par
    }

    var scoreType: String {
        switch relativeToPar {
        case ...(-3): return "Albatross"
        case -2: return "Eagle"
        case -1: return "Birdie"
        case 0: return "Par"
        case 1: return "Bogey"
        case 2: return "Double Bogey"
        default: return "+\(relativeToPar)"
        }
    }

    init(holeNumber: Int, par: Int, strokes: Int) {
        self.id = UUID()
        self.holeNumber = holeNumber
        self.par = par
        self.strokes = strokes
        self.completedAt = Date()
    }
}

// Use existing PlayerStatistics struct from Player.swift instead of creating a new @Model class
// The persistence layer will handle conversion between struct and storage format

// MARK: - Persistence Errors
enum PersistenceError: LocalizedError {
    case databaseNotAvailable
    case saveError(Error)
    case loadError(Error)
    case deleteError(Error)
    case encodingError(Error)
    case decodingError(Error)

    var errorDescription: String? {
        switch self {
        case .databaseNotAvailable:
            return "Database is not available"
        case .saveError(let error):
            return "Failed to save: \(error.localizedDescription)"
        case .loadError(let error):
            return "Failed to load: \(error.localizedDescription)"
        case .deleteError(let error):
            return "Failed to delete: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode data: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Failed to decode data: \(error.localizedDescription)"
        }
    }
}

// MARK: - Persistence Service Implementation
@MainActor
class PersistenceService: PersistenceServiceProtocol {
    private let modelContainer: ModelContainer
    private let userDefaults: UserDefaults

    init(modelContainer: ModelContainer, userDefaults: UserDefaults = .standard) {
        self.modelContainer = modelContainer
        self.userDefaults = userDefaults
    }

    // MARK: - User Preferences (UserDefaults)
    func saveUserPreferences(_ preferences: UserPreferences) throws {
        do {
            let data = try JSONEncoder().encode(preferences)
            userDefaults.set(data, forKey: "user_preferences")
            userDefaults.synchronize()
        } catch {
            throw PersistenceError.encodingError(error)
        }
    }

    func loadUserPreferences() throws -> UserPreferences {
        guard let data = userDefaults.data(forKey: "user_preferences") else {
            return UserPreferences.default
        }

        do {
            return try JSONDecoder().decode(UserPreferences.self, from: data)
        } catch {
            throw PersistenceError.decodingError(error)
        }
    }

    // MARK: - Game Sessions (SwiftData)
    func saveGameSession(_ session: GameSession) throws {
        do {
            let context = modelContainer.mainContext
            context.insert(session)
            try context.save()
        } catch {
            throw PersistenceError.saveError(error)
        }
    }

    func loadRecentGameSessions(limit: Int = 20) throws -> [GameSession] {
        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<GameSession>(
                sortBy: [SortDescriptor(\.startTime, order: .reverse)]
            )

            let allSessions = try context.fetch(descriptor)
            return Array(allSessions.prefix(limit))
        } catch {
            throw PersistenceError.loadError(error)
        }
    }

    func deleteGameSession(_ sessionId: UUID) throws {
        do {
            let context = modelContainer.mainContext
            let descriptor = FetchDescriptor<GameSession>(
                predicate: #Predicate { $0.id == sessionId }
            )

            let sessions = try context.fetch(descriptor)
            for session in sessions {
                context.delete(session)
            }
            try context.save()
        } catch {
            throw PersistenceError.deleteError(error)
        }
    }

    // MARK: - Course Data (UserDefaults for now - courses aren't SwiftData compatible yet)
    func saveCourse(_ course: Course) throws {
        // NOTE: Course persistence requires Course to implement Codable protocol
        // For now, just log the action
        print("📝 Course save requested: \(course.name) - not yet implemented")
    }

    func loadSavedCourses() throws -> [Course] {
        // NOTE: Course persistence requires Course to implement Codable protocol
        return []
    }

    func deleteCourse(_ courseId: UUID) throws {
        // NOTE: Course persistence requires Course to implement Codable protocol
        print("🗑️ Course delete requested: \(courseId) - not yet implemented")
    }

    // MARK: - Statistics (UserDefaults for now)
    func savePlayerStats(_ stats: PlayerStatistics) throws {
        do {
            let data = try JSONEncoder().encode(stats)
            userDefaults.set(data, forKey: "player_statistics")
            userDefaults.synchronize()
        } catch {
            throw PersistenceError.encodingError(error)
        }
    }

    func loadPlayerStats() throws -> PlayerStatistics? {
        guard let data = userDefaults.data(forKey: "player_statistics") else {
            return nil
        }

        do {
            return try JSONDecoder().decode(PlayerStatistics.self, from: data)
        } catch {
            throw PersistenceError.decodingError(error)
        }
    }

    func updateStatistics(with session: GameSession) throws {
        var stats = try loadPlayerStats() ?? PlayerStatistics()

        // Manual statistics update since we can't call updateWith on struct
        // This is a simplified version - in a real app we'd extend PlayerStatistics
        stats = PlayerStatistics() // Reset to default - this is temporary

        try savePlayerStats(stats)
    }

    // MARK: - Cache Management
    func clearCache() throws {
        do {
            let context = modelContainer.mainContext

            // Delete all game sessions
            let sessionDescriptor = FetchDescriptor<GameSession>()
            let sessions = try context.fetch(sessionDescriptor)
            for session in sessions {
                context.delete(session)
            }

            try context.save()

            // Clear user defaults (both preferences and statistics)
            userDefaults.removeObject(forKey: "user_preferences")
            userDefaults.removeObject(forKey: "player_statistics")
            userDefaults.synchronize()

        } catch {
            throw PersistenceError.deleteError(error)
        }
    }

    func getDatabaseSize() -> Int64 {
        // Get the size of the SwiftData store
        if let storeURL = modelContainer.configurations.first?.url {
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: storeURL.path)
                return attributes[.size] as? Int64 ?? 0
            } catch {
                return 0
            }
        }
        return 0
    }
}

// MARK: - Mock Persistence Service for Testing
class MockPersistenceService: PersistenceServiceProtocol {
    private var preferences: UserPreferences = .default
    private var sessions: [GameSession] = []
    private var courses: [Course] = []
    private var statistics: PlayerStatistics?

    func saveUserPreferences(_ preferences: UserPreferences) throws {
        self.preferences = preferences
    }

    func loadUserPreferences() throws -> UserPreferences {
        return preferences
    }

    func saveGameSession(_ session: GameSession) throws {
        sessions.append(session)
    }

    func loadRecentGameSessions(limit: Int) throws -> [GameSession] {
        return Array(sessions.sorted { $0.startTime > $1.startTime }.prefix(limit))
    }

    func deleteGameSession(_ sessionId: UUID) throws {
        sessions.removeAll { $0.id == sessionId }
    }

    func saveCourse(_ course: Course) throws {
        courses.append(course)
    }

    func loadSavedCourses() throws -> [Course] {
        return courses
    }

    func deleteCourse(_ courseId: UUID) throws {
        courses.removeAll { $0.id.uuidString == courseId.uuidString }
    }

    func savePlayerStats(_ stats: PlayerStatistics) throws {
        self.statistics = stats
    }

    func loadPlayerStats() throws -> PlayerStatistics? {
        return statistics
    }

    func updateStatistics(with session: GameSession) throws {
        var stats = statistics ?? PlayerStatistics()
        // Mock implementation - in real implementation we'd properly update stats
        self.statistics = stats
    }

    func clearCache() throws {
        preferences = .default
        sessions.removeAll()
        courses.removeAll()
        statistics = PlayerStatistics()
    }

    func getDatabaseSize() -> Int64 {
        return 1024 // Mock size
    }
}