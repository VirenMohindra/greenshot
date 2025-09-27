//
//  Difficulty.swift
//  runner
//
//  Hole difficulty configuration value object
//

import Foundation
import CoreGraphics

struct Difficulty: Equatable, Hashable {
    let level: Float // 0.0 to 1.0

    init(_ level: Float) {
        self.level = max(0.0, min(1.0, level))
    }

    init(level: Double) {
        self.level = max(0.0, min(1.0, Float(level)))
    }

    init(holeNumber: Int, totalHoles: Int = 18) {
        // Progressive difficulty throughout the round
        self.level = min(Float(holeNumber - 1) / Float(totalHoles - 1), 1.0)
    }
}

// MARK: - Difficulty Properties
extension Difficulty {
    var isBeginner: Bool { level < 0.3 }
    var isIntermediate: Bool { level >= 0.3 && level < 0.7 }
    var isAdvanced: Bool { level >= 0.7 }

    var displayName: String {
        switch level {
        case 0.0..<0.3: return "Beginner"
        case 0.3..<0.7: return "Intermediate"
        default: return "Advanced"
        }
    }
}

// MARK: - Course Generation Parameters
extension Difficulty {
    var fairwayWidth: CGFloat {
        100 - (CGFloat(level) * 30) // 100px to 70px
    }

    var obstacleCount: Int {
        Int(level * 5) + 1 // 1 to 6 obstacles
    }

    var waterHazardChance: Float {
        0.2 + (level * 0.6) // 20% to 80% chance
    }

    var bunkerCount: Int {
        Int(3 + level * 6) // 3 to 9 bunkers
    }

    var treeCount: Int {
        Int(8 + level * 12) // 8 to 20 trees - much more challenging!
    }

    var courseCurvature: Float {
        level * 0.7 // More curves for harder holes
    }

    var holePositionVariation: CGFloat {
        CGFloat(level) * 0.35 // Up to 35% variation from center
    }
}

// MARK: - Constants
extension Difficulty {
    static let beginner = Difficulty(0.0)
    static let intermediate = Difficulty(0.5)
    static let advanced = Difficulty(1.0)
}