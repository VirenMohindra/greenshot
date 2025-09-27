//
//  Hole.swift
//  runner
//
//  Golf hole entity representing a complete hole with tee, pin, obstacles
//

import Foundation
import CoreGraphics

class Hole {
    let id: UUID
    let number: Int
    let par: Int
    let difficulty: Difficulty

    private(set) var teePosition: Position
    private(set) var pinPosition: Position
    private(set) var fairwayPath: CGPath
    private(set) var obstacles: [Obstacle]

    // Derived properties
    private(set) var distance: CGFloat
    private(set) var greenPosition: Position
    private(set) var greenRadius: CGFloat = 45.0

    init(
        number: Int,
        par: Int,
        difficulty: Difficulty,
        teePosition: Position,
        pinPosition: Position,
        fairwayPath: CGPath,
        obstacles: [Obstacle] = []
    ) {
        self.id = UUID()
        self.number = number
        self.par = par
        self.difficulty = difficulty
        self.teePosition = teePosition
        self.pinPosition = pinPosition
        self.fairwayPath = fairwayPath
        self.obstacles = obstacles
        self.distance = teePosition.distance(to: pinPosition)
        self.greenPosition = pinPosition // Pin is at center of green
    }
}

// MARK: - Hole Properties
extension Hole {
    var yardage: Int {
        Int(distance * 0.5) // Rough conversion from points to yards for display
    }

    var holeDescription: String {
        "Hole \(number) - Par \(par) - \(yardage) yards"
    }

    var isShortHole: Bool { par == 3 }
    var isMediumHole: Bool { par == 4 }
    var isLongHole: Bool { par == 5 }
}

// MARK: - Spatial Queries
extension Hole {
    func isBallInHole(_ ballPosition: Position, tolerance: CGFloat = 15.0) -> Bool {
        ballPosition.distance(to: pinPosition) <= tolerance
    }

    func isBallOnGreen(_ ballPosition: Position) -> Bool {
        ballPosition.distance(to: greenPosition) <= greenRadius
    }

    func isBallOnFairway(_ ballPosition: Position) -> Bool {
        fairwayPath.contains(ballPosition.cgPoint)
    }

    func isBallNearTee(_ ballPosition: Position, tolerance: CGFloat = 80.0) -> Bool {
        ballPosition.distance(to: teePosition) <= tolerance
    }

    func obstacleAt(_ position: Position, tolerance: CGFloat = 10.0) -> Obstacle? {
        obstacles.first { obstacle in
            position.distance(to: obstacle.position) <= tolerance
        }
    }
}

// MARK: - Hole State
extension Hole {
    func isCompleted(by score: Score) -> Bool {
        score.strokes > 0
    }
}
