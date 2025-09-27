//
//  NavigateHolesUseCase.swift
//  GreenShot
//
//  Use case for managing hole progression and navigation
//

import Foundation

protocol NavigateHolesUseCaseProtocol {
    func startNewRound(player: Player, course: Course) -> RoundStartResult
    func moveToNextHole(course: Course, player: Player) -> HoleNavigationResult
    func resetToTee(ball: GolfBall, currentHole: Hole) -> ResetResult
    func completeRound(course: Course, player: Player) -> RoundCompletionResult
}

class NavigateHolesUseCase: NavigateHolesUseCaseProtocol {

    func startNewRound(player: Player, course: Course) -> RoundStartResult {
        // Reset course to first hole
        course.reset()

        // Start new round for player
        player.startNewRound(on: course)

        guard let firstHole = course.currentHole else {
            return .failure(error: "No holes available in course")
        }

        return .success(hole: firstHole)
    }

    func moveToNextHole(course: Course, player: Player) -> HoleNavigationResult {
        // Move to next hole
        guard let nextHole = course.moveToNextHole() else {
            // Round is complete
            let completionResult = completeRound(course: course, player: player)
            return .roundComplete(result: completionResult)
        }

        return .success(
            hole: nextHole,
            progress: course.progressDescription,
            isLastHole: course.isOnLastHole
        )
    }

    func resetToTee(ball: GolfBall, currentHole: Hole) -> ResetResult {
        // Reset ball to tee position
        ball.reset(to: currentHole.teePosition)

        return .success(newPosition: currentHole.teePosition)
    }

    func completeRound(course: Course, player: Player) -> RoundCompletionResult {
        // Mark the current round as complete first
        guard let currentRound = player.currentRound else {
            return .failure(error: "No active round to complete")
        }

        currentRound.completeRound()

        // Complete player's current round
        guard let completedRound = player.completeCurrentRound() else {
            return .failure(error: "Failed to complete round")
        }

        return .success(
            finalScore: completedRound.totalScore,
            totalStrokes: completedRound.totalStrokes,
            totalPar: completedRound.totalPar,
            completedRound: completedRound
        )
    }
}

// MARK: - Result Types
enum RoundStartResult {
    case success(hole: Hole)
    case failure(error: String)
}

enum HoleNavigationResult {
    case success(hole: Hole, progress: String, isLastHole: Bool)
    case roundComplete(result: RoundCompletionResult)
}

enum ResetResult {
    case success(newPosition: Position)
    case failure(error: String)
}

enum RoundCompletionResult {
    case success(finalScore: Int, totalStrokes: Int, totalPar: Int, completedRound: Round)
    case failure(error: String)
}