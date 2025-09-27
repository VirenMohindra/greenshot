//
//  Course.swift
//  GreenShot
//
//  Golf course entity containing collection of holes
//

import Foundation
import CoreGraphics

class Course {
    let id: UUID
    let name: String
    private(set) var holes: [Hole]
    private(set) var currentHoleIndex: Int = 0

    // Course dimensions for consistent generation
    let worldSize: CGSize

    init(name: String, holes: [Hole], worldSize: CGSize) {
        self.id = UUID()
        self.name = name
        self.holes = holes
        self.worldSize = worldSize
    }
}

// MARK: - Course Properties
extension Course {
    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }

    var totalHoles: Int {
        holes.count
    }

    var isComplete: Bool {
        currentHoleIndex >= holes.count
    }

    var frontNine: [Hole] {
        Array(holes.prefix(9))
    }

    var backNine: [Hole] {
        holes.count > 9 ? Array(holes.dropFirst(9)) : []
    }

    var currentHole: Hole? {
        guard currentHoleIndex < holes.count else { return nil }
        return holes[currentHoleIndex]
    }

    var nextHole: Hole? {
        let nextIndex = currentHoleIndex + 1
        guard nextIndex < holes.count else { return nil }
        return holes[nextIndex]
    }

    var isOnLastHole: Bool {
        currentHoleIndex == holes.count - 1
    }

    var progressDescription: String {
        guard let current = currentHole else { return "Course Complete" }
        return "Hole \(current.number) of \(totalHoles)"
    }
}

// MARK: - Navigation
extension Course {
    func moveToNextHole() -> Hole? {
        guard !isComplete else { return nil }
        currentHoleIndex += 1
        return currentHole
    }

    func moveToPreviousHole() -> Hole? {
        guard currentHoleIndex > 0 else { return nil }
        currentHoleIndex -= 1
        return currentHole
    }

    func moveToHole(_ holeNumber: Int) -> Hole? {
        let index = holeNumber - 1
        guard index >= 0 && index < holes.count else { return nil }
        currentHoleIndex = index
        return currentHole
    }

    func reset() {
        currentHoleIndex = 0
    }
}

// MARK: - Course Statistics
extension Course {
    var averagePar: Double {
        guard !holes.isEmpty else { return 0 }
        return Double(totalPar) / Double(holes.count)
    }

    var parThreeCount: Int {
        holes.filter { $0.par == 3 }.count
    }

    var parFourCount: Int {
        holes.filter { $0.par == 4 }.count
    }

    var parFiveCount: Int {
        holes.filter { $0.par == 5 }.count
    }

    var difficultyDistribution: (beginner: Int, intermediate: Int, advanced: Int) {
        let beginner = holes.filter { $0.difficulty.isBeginner }.count
        let intermediate = holes.filter { $0.difficulty.isIntermediate }.count
        let advanced = holes.filter { $0.difficulty.isAdvanced }.count
        return (beginner, intermediate, advanced)
    }
}