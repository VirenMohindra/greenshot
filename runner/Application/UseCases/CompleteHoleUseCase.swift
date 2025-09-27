//
//  CompleteHoleUseCase.swift
//  runner
//
//  Use case for handling hole completion and scoring
//

import Foundation

protocol CompleteHoleUseCaseProtocol {
    func completeHole(
        hole: Hole,
        strokes: Int,
        player: Player
    ) -> HoleCompletionResult

    func checkHoleCompletion(
        ballPosition: Position,
        hole: Hole,
        ballVelocity: Velocity
    ) -> Bool

    func calculateFinalScore(hole: Hole, strokes: Int) -> Score
}

class CompleteHoleUseCase: CompleteHoleUseCaseProtocol {
    private let scoringService: ScoringServiceProtocol

    init(scoringService: ScoringServiceProtocol) {
        self.scoringService = scoringService
    }

    func completeHole(
        hole: Hole,
        strokes: Int,
        player: Player
    ) -> HoleCompletionResult {
        // Create final score
        let score = calculateFinalScore(hole: hole, strokes: strokes)

        // Record score for player
        player.recordScore(score, for: hole)

        // Determine celebration level
        let celebrationLevel = scoringService.getCelebrationLevel(score)

        // Check for achievements
        let newAchievements = checkForAchievements(score: score, hole: hole)

        return HoleCompletionResult(
            score: score,
            celebrationLevel: celebrationLevel,
            newAchievements: newAchievements,
            isRoundComplete: false // This would be determined by game controller
        )
    }

    func checkHoleCompletion(
        ballPosition: Position,
        hole: Hole,
        ballVelocity: Velocity
    ) -> Bool {
        // Ball must be in hole and moving slowly enough
        return hole.isBallInHole(ballPosition) && ballVelocity.magnitude < 100
    }

    func calculateFinalScore(hole: Hole, strokes: Int) -> Score {
        scoringService.createScore(strokes: strokes, par: hole.par)
    }

    // MARK: - Private Methods
    private func checkForAchievements(score: Score, hole: Hole) -> [Achievement] {
        var achievements: [Achievement] = []

        if score.isHoleInOne {
            achievements.append(Achievement(
                title: "Hole in One!",
                description: "Achieved a hole in one on hole \(hole.number)",
                icon: "trophy.fill"
            ))
        }

        if score.isEagle {
            achievements.append(Achievement(
                title: "Eagle!",
                description: "Scored an eagle on hole \(hole.number)",
                icon: "bird.fill"
            ))
        }

        return achievements
    }
}

// MARK: - Result Types
struct HoleCompletionResult {
    let score: Score
    let celebrationLevel: CelebrationLevel
    let newAchievements: [Achievement]
    let isRoundComplete: Bool
}