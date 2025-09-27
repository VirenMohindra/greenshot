//
//  ScoringService.swift
//  GreenShot
//
//  Domain service for golf scoring logic and calculations
//

import Foundation
import UIKit

protocol ScoringServiceProtocol {
    func createScore(strokes: Int, par: Int) -> Score
    func calculateParForDistance(_ distance: CGFloat, difficulty: Difficulty) -> Int
    func getScoreColor(for score: Score) -> UIColor
    func getScoreDisplayColor(for score: Score) -> UIColor
    func shouldCelebrate(_ score: Score) -> Bool
    func getCelebrationLevel(_ score: Score) -> CelebrationLevel
}

class ScoringService: ScoringServiceProtocol {

    func createScore(strokes: Int, par: Int) -> Score {
        Score(strokes: strokes, par: par)
    }

    func calculateParForDistance(_ distance: CGFloat, difficulty: Difficulty) -> Int {
        // Realistic golf distance to par conversion (similar to real golf)
        let baseDistance = distance

        // Apply difficulty modifier - harder holes may "play longer"
        let difficultyModifier = 1.0 + CGFloat(difficulty.level) * 0.4
        let adjustedDistance = baseDistance * difficultyModifier

        // Standard golf distance guidelines:
        // Par 3: Up to 250 yards (harder/longer par 3s)
        // Par 4: 250-450 yards
        // Par 5: 450+ yards
        switch adjustedDistance {
        case 0..<250: return 3
        case 250..<450: return 4
        case 450...: return 5
        default: return 4
        }
    }

    func getScoreColor(for score: Score) -> UIColor {
        switch score.quality {
        case .excellent:
            return UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0) // Bright green
        case .good:
            return UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0) // Light green
        case .average:
            return .white
        case .poor:
            return UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0) // Yellow
        case .terrible:
            return UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0) // Red
        }
    }

    func getScoreDisplayColor(for score: Score) -> UIColor {
        switch score.quality {
        case .excellent:
            return UIColor(red: 0.0, green: 0.8, blue: 0.0, alpha: 1.0)
        case .good:
            return UIColor(red: 0.2, green: 0.9, blue: 0.2, alpha: 1.0)
        case .average:
            return .white
        case .poor:
            return UIColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        case .terrible:
            return UIColor(red: 1.0, green: 0.4, blue: 0.4, alpha: 1.0)
        }
    }

    func shouldCelebrate(_ score: Score) -> Bool {
        score.quality == .excellent || score.quality == .good || score.isHoleInOne
    }

    func getCelebrationLevel(_ score: Score) -> CelebrationLevel {
        if score.isHoleInOne {
            return .spectacular
        }

        switch score.quality {
        case .excellent: return .major
        case .good: return .moderate
        case .average: return .minor
        default: return .none
        }
    }
}

// MARK: - Celebration Levels
enum CelebrationLevel {
    case none
    case minor
    case moderate
    case major
    case spectacular

    var particleCount: Int {
        switch self {
        case .none: return 0
        case .minor: return 3
        case .moderate: return 6
        case .major: return 10
        case .spectacular: return 15
        }
    }

    var duration: TimeInterval {
        switch self {
        case .none: return 0
        case .minor: return 1.0
        case .moderate: return 2.0
        case .major: return 3.0
        case .spectacular: return 4.0
        }
    }

    var shouldShowMessage: Bool {
        self != .none
    }
}