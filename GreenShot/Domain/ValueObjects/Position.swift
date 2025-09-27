//
//  Position.swift
//  GreenShot
//
//  2D position value object for golf game coordinates
//

import Foundation
import CoreGraphics

struct Position: Equatable, Hashable {
    let x: CGFloat
    let y: CGFloat

    init(x: CGFloat, y: CGFloat) {
        self.x = x
        self.y = y
    }

    init(_ point: CGPoint) {
        self.x = point.x
        self.y = point.y
    }
}

// MARK: - Computed Properties
extension Position {
    var cgPoint: CGPoint {
        CGPoint(x: x, y: y)
    }
}

// MARK: - Golf-Specific Operations
extension Position {
    func distance(to other: Position) -> CGFloat {
        sqrt(pow(other.x - x, 2) + pow(other.y - y, 2))
    }

    func direction(to other: Position) -> CGFloat {
        atan2(other.y - y, other.x - x)
    }

    func offset(by dx: CGFloat, dy: CGFloat) -> Position {
        Position(x: x + dx, y: y + dy)
    }

    func offset(by vector: Velocity) -> Position {
        Position(x: x + vector.dx, y: y + vector.dy)
    }

    func minus(_ other: Position) -> Position {
        Position(x: x - other.x, y: y - other.y)
    }

    func normalized() -> Position {
        let magnitude = sqrt(x * x + y * y)
        guard magnitude > 0 else { return Position.zero }
        return Position(x: x / magnitude, y: y / magnitude)
    }
}

// MARK: - Constants
extension Position {
    static let zero = Position(x: 0, y: 0)
}