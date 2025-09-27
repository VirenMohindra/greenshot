//
//  Velocity.swift
//  runner
//
//  Velocity value object for golf ball physics
//

import Foundation
import CoreGraphics

struct Velocity: Equatable, Hashable {
    let dx: CGFloat
    let dy: CGFloat

    init(dx: CGFloat, dy: CGFloat) {
        self.dx = dx
        self.dy = dy
    }

    init(_ vector: CGVector) {
        self.dx = vector.dx
        self.dy = vector.dy
    }
}

// MARK: - Computed Properties
extension Velocity {
    var cgVector: CGVector {
        CGVector(dx: dx, dy: dy)
    }

    var magnitude: CGFloat {
        sqrt(dx * dx + dy * dy)
    }

    var direction: CGFloat {
        atan2(dy, dx)
    }

    var isStationary: Bool {
        magnitude < Constants.Ball.stationaryThreshold
    }
}

// MARK: - Physics Operations
extension Velocity {
    func scaled(by factor: CGFloat) -> Velocity {
        Velocity(dx: dx * factor, dy: dy * factor)
    }

    func withDamping(_ damping: CGFloat) -> Velocity {
        Velocity(dx: dx * damping, dy: dy * damping)
    }

    func normalized() -> Velocity {
        let mag = magnitude
        guard mag > 0 else { return .zero }
        return Velocity(dx: dx / mag, dy: dy / mag)
    }

    func limited(to maxMagnitude: CGFloat) -> Velocity {
        let mag = magnitude
        guard mag > maxMagnitude else { return self }
        let factor = maxMagnitude / mag
        return scaled(by: factor)
    }
}

// MARK: - Constants
extension Velocity {
    static let zero = Velocity(dx: 0, dy: 0)
}

// MARK: - Golf Physics Constants
extension Velocity {
    static let maxGolfBallSpeed: CGFloat = 200.0
}