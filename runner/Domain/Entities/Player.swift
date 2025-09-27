//
//  Player.swift
//  runner
//
//  Golf player entity with statistics and progress tracking
//

import Foundation
import GameKit

class Player {
    let id: UUID
    let gameCenterID: String?
    private(set) var displayName: String
    private(set) var statistics: PlayerStatistics
    private(set) var currentRound: Round?

    init(
        id: UUID = UUID(),
        gameCenterID: String? = nil,
        displayName: String,
        statistics: PlayerStatistics = PlayerStatistics()
    ) {
        self.id = id
        self.gameCenterID = gameCenterID
        self.displayName = displayName
        self.statistics = statistics
    }
}

// MARK: - Player Management
extension Player {
    func updateDisplayName(_ name: String) {
        displayName = name
    }

    func startNewRound(on course: Course) {
        currentRound = Round(courseId: course.id, courseName: course.name)
    }

    func completeCurrentRound() -> Round? {
        defer { currentRound = nil }
        if let round = currentRound, round.isComplete {
            statistics.addCompletedRound(round)
            return round
        }
        return nil
    }
}

// MARK: - Score Tracking
extension Player {
    func recordScore(_ score: Score, for hole: Hole) {
        currentRound?.recordScore(score, for: hole)
    }

    func getCurrentScore() -> Int {
        currentRound?.totalScore ?? 0
    }

    func getCurrentRoundPar() -> Int {
        currentRound?.totalPar ?? 0
    }
}

// MARK: - Statistics
struct PlayerStatistics: Codable {
    private(set) var roundsPlayed: Int = 0
    private(set) var totalStrokes: Int = 0
    private(set) var holesCompleted: Int = 0
    private(set) var bestScore: Int?
    private(set) var worstScore: Int?
    private(set) var achievements: [Achievement] = []

    // Scoring records
    private(set) var holesInOne: Int = 0
    private(set) var eagles: Int = 0
    private(set) var birdies: Int = 0
    private(set) var pars: Int = 0
    private(set) var bogeys: Int = 0

    mutating func addCompletedRound(_ round: Round) {
        roundsPlayed += 1
        totalStrokes += round.totalStrokes
        holesCompleted += round.completedHoles.count

        let roundScore = round.totalScore
        if bestScore == nil || roundScore < bestScore! {
            bestScore = roundScore
        }
        if worstScore == nil || roundScore > worstScore! {
            worstScore = roundScore
        }

        // Update score type counts
        for holeScore in round.completedHoles.values {
            updateScoreTypeCounts(for: holeScore)
        }
    }

    private mutating func updateScoreTypeCounts(for score: Score) {
        if score.isHoleInOne {
            holesInOne += 1
        } else if score.isEagle {
            eagles += 1
        } else if score.isBirdie {
            birdies += 1
        } else if score.isPar {
            pars += 1
        } else if score.isBogey {
            bogeys += 1
        }
    }
}

// MARK: - Computed Statistics
extension PlayerStatistics {
    var averageScore: Double {
        guard roundsPlayed > 0 else { return 0 }
        return Double(totalStrokes) / Double(roundsPlayed)
    }

    var averageScorePerHole: Double {
        guard holesCompleted > 0 else { return 0 }
        return Double(totalStrokes) / Double(holesCompleted)
    }

    var birdiePercentage: Double {
        guard holesCompleted > 0 else { return 0 }
        return Double(birdies) / Double(holesCompleted) * 100
    }

    var parPercentage: Double {
        guard holesCompleted > 0 else { return 0 }
        return Double(pars) / Double(holesCompleted) * 100
    }
}

// MARK: - Round Tracking
class Round {
    let id: UUID
    let courseId: UUID
    let courseName: String
    let startTime: Date
    private(set) var endTime: Date?
    private(set) var completedHoles: [Int: Score] = [:] // Hole number -> Score

    init(courseId: UUID, courseName: String) {
        self.id = UUID()
        self.courseId = courseId
        self.courseName = courseName
        self.startTime = Date()
    }

    func recordScore(_ score: Score, for hole: Hole) {
        completedHoles[hole.number] = score
    }

    func completeRound() {
        endTime = Date()
    }
}

// MARK: - Round Properties
extension Round {
    var isComplete: Bool {
        endTime != nil
    }

    var totalStrokes: Int {
        completedHoles.values.reduce(0) { $0 + $1.strokes }
    }

    var totalPar: Int {
        completedHoles.values.reduce(0) { $0 + $1.par }
    }

    var totalScore: Int {
        totalStrokes - totalPar
    }

    var duration: TimeInterval? {
        guard let endTime = endTime else { return nil }
        return endTime.timeIntervalSince(startTime)
    }
}

// MARK: - Achievements
struct Achievement: Codable {
    let id: UUID
    let title: String
    let description: String
    let unlockedDate: Date
    let icon: String

    init(title: String, description: String, icon: String) {
        self.id = UUID()
        self.title = title
        self.description = description
        self.icon = icon
        self.unlockedDate = Date()
    }
}