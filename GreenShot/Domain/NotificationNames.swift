//
//  NotificationNames.swift
//  GreenShot
//
//  Type-safe notification names for the golf game
//

import Foundation

/// Type-safe notification names for game events
struct NotificationNames {

    // MARK: - Game State
    static let gameStateChanged = NSNotification.Name("gameStateChanged")
    static let gameStarted = NSNotification.Name("gameStarted")
    static let gameEnded = NSNotification.Name("gameEnded")
    static let gamePaused = NSNotification.Name("gamePaused")
    static let gameResumed = NSNotification.Name("gameResumed")

    // MARK: - Hole Events
    static let holeStarted = NSNotification.Name("holeStarted")
    static let holeCompleted = NSNotification.Name("holeCompleted")
    static let holeSkipped = NSNotification.Name("holeSkipped")

    // MARK: - Shot Events
    static let shotTaken = NSNotification.Name("shotTaken")
    static let shotCompleted = NSNotification.Name("shotCompleted")
    static let ballStopped = NSNotification.Name("ballStopped")

    // MARK: - Collision Events
    static let ballEnteredHole = NSNotification.Name("ballEnteredHole")
    static let ballHitObstacle = NSNotification.Name("ballHitObstacle")
    static let ballWentOutOfBounds = NSNotification.Name("ballWentOutOfBounds")

    // MARK: - Score Events
    static let scoreUpdated = NSNotification.Name("scoreUpdated")
    static let achievementUnlocked = NSNotification.Name("achievementUnlocked")
    static let newRecord = NSNotification.Name("newRecord")

    // MARK: - UI Events
    static let cameraPositionChanged = NSNotification.Name("cameraPositionChanged")
    static let zoomLevelChanged = NSNotification.Name("zoomLevelChanged")
    static let settingsChanged = NSNotification.Name("settingsChanged")

    // MARK: - Course Events
    static let courseGenerated = NSNotification.Name("courseGenerated")
    static let courseLoaded = NSNotification.Name("courseLoaded")

    // MARK: - Network Events (for future multiplayer)
    static let networkConnectionChanged = NSNotification.Name("networkConnectionChanged")
    static let multiplayerGameJoined = NSNotification.Name("multiplayerGameJoined")
    static let multiplayerGameLeft = NSNotification.Name("multiplayerGameLeft")
}

/// Convenient extension for posting notifications with type safety
extension NotificationCenter {

    // MARK: - Game State Notifications
    func postGameStateChanged(newState: GameState) {
        post(name: NotificationNames.gameStateChanged, object: nil, userInfo: ["newState": newState])
    }

    func postGameStarted() {
        post(name: NotificationNames.gameStarted, object: nil)
    }

    func postGameEnded(finalScore: Score) {
        post(name: NotificationNames.gameEnded, object: nil, userInfo: ["finalScore": finalScore])
    }

    // MARK: - Hole Notifications
    func postHoleStarted(hole: Hole) {
        post(name: NotificationNames.holeStarted, object: nil, userInfo: ["hole": hole])
    }

    func postHoleCompleted(hole: Hole, score: Score) {
        post(name: NotificationNames.holeCompleted, object: nil, userInfo: ["hole": hole, "score": score])
    }

    // MARK: - Shot Notifications
    func postShotTaken(power: Float, direction: Float) {
        post(name: NotificationNames.shotTaken, object: nil, userInfo: ["power": power, "direction": direction])
    }

    func postBallStopped(position: Position) {
        post(name: NotificationNames.ballStopped, object: nil, userInfo: ["position": position])
    }

    // MARK: - Collision Notifications
    func postBallEnteredHole(position: Position) {
        post(name: NotificationNames.ballEnteredHole, object: nil, userInfo: ["position": position])
    }

    func postBallHitObstacle(obstacle: Obstacle, effect: ObstacleEffect) {
        post(name: NotificationNames.ballHitObstacle, object: nil, userInfo: ["obstacle": obstacle, "effect": effect])
    }

    func postBallWentOutOfBounds(position: Position) {
        post(name: NotificationNames.ballWentOutOfBounds, object: nil, userInfo: ["position": position])
    }

    // MARK: - Score Notifications
    func postScoreUpdated(newScore: Score) {
        post(name: NotificationNames.scoreUpdated, object: nil, userInfo: ["newScore": newScore])
    }

    func postAchievementUnlocked(achievement: Achievement) {
        post(name: NotificationNames.achievementUnlocked, object: nil, userInfo: ["achievement": achievement])
    }

    // MARK: - Camera Notifications
    func postCameraPositionChanged(newPosition: Position) {
        post(name: NotificationNames.cameraPositionChanged, object: nil, userInfo: ["newPosition": newPosition])
    }

    func postZoomLevelChanged(newZoom: CGFloat) {
        post(name: NotificationNames.zoomLevelChanged, object: nil, userInfo: ["newZoom": newZoom])
    }

    // MARK: - Course Notifications
    func postCourseGenerated(course: Course) {
        post(name: NotificationNames.courseGenerated, object: nil, userInfo: ["course": course])
    }
}