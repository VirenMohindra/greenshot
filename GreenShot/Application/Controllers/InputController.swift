//
//  InputController.swift
//  GreenShot
//
//  Controller for handling touch input and gesture processing
//

import Foundation
import UIKit

protocol InputControllerDelegate: AnyObject {
    func inputController(_ controller: InputController, didStartDrag at: Position)
    func inputController(_ controller: InputController, didUpdateDrag to: Position, from start: Position)
    func inputController(_ controller: InputController, didEndDrag at: Position, from start: Position)
    func inputController(_ controller: InputController, didCancelDrag: Void)
    func inputController(_ controller: InputController, didTapResetButton: Void)
    func inputController(_ controller: InputController, didStartPan at: Position)
    func inputController(_ controller: InputController, didUpdatePan to: Position, delta: Position)
    func inputController(_ controller: InputController, didEndPan: Void)
}

class InputController {
    weak var delegate: InputControllerDelegate?

    // MARK: - Input State
    private var inputState: InputState = .idle
    private var dragStartPosition: Position = .zero
    private var panStartPosition: Position = .zero
    private var lastPanPosition: Position = .zero

    // MARK: - Configuration
    private let ballControlRadius: CGFloat = 80.0
    private let resetButtonRadius: CGFloat = 30.0
    private let cancelGestureRadius: CGFloat = 25.0

    init() {}
}

// MARK: - Touch Input Processing
extension InputController {
    func processTouchBegan(
        at location: Position,
        ballPosition: Position,
        ballVelocity: Velocity,
        resetButtonPosition: Position?
    ) {
        // Check if reset button was tapped
        if let resetPos = resetButtonPosition,
           location.distance(to: resetPos) < resetButtonRadius {
            delegate?.inputController(self, didTapResetButton: ())
            return
        }

        // Check if touch is near ball and ball is stationary
        let distanceToBall = location.distance(to: ballPosition)
        let ballIsStationary = ballVelocity.isStationary

        print("🎯 Touch at: \(location), Ball at: \(ballPosition), Distance: \(distanceToBall), Ball control radius: \(ballControlRadius)")
        print("⚽ Ball velocity stationary: \(ballIsStationary)")

        if distanceToBall < ballControlRadius && ballIsStationary {
            // Start ball drag
            print("🏌️ Starting ball drag")
            inputState = .draggingBall
            dragStartPosition = ballPosition
            delegate?.inputController(self, didStartDrag: dragStartPosition)
        } else {
            // Start camera pan
            print("📷 Starting camera pan")
            inputState = .panningCamera
            panStartPosition = location
            lastPanPosition = location
            delegate?.inputController(self, didStartPan: location)
        }
    }

    func processTouchMoved(to location: Position) {
        switch inputState {
        case .draggingBall:
            // Check for cancel gesture (dragging back close to ball)
            let distanceFromBall = location.distance(to: dragStartPosition)
            if distanceFromBall < cancelGestureRadius {
                delegate?.inputController(self, didCancelDrag: ())
                inputState = .idle
            } else {
                delegate?.inputController(self, didUpdateDrag: location, from: dragStartPosition)
            }

        case .panningCamera:
            let delta = Position(
                x: location.x - lastPanPosition.x,
                y: location.y - lastPanPosition.y
            )
            delegate?.inputController(self, didUpdatePan: location, delta: delta)
            lastPanPosition = location

        case .idle:
            break
        }
    }

    func processTouchEnded(at location: Position) {
        switch inputState {
        case .draggingBall:
            delegate?.inputController(self, didEndDrag: location, from: dragStartPosition)

        case .panningCamera:
            delegate?.inputController(self, didEndPan: ())

        case .idle:
            break
        }

        inputState = .idle
    }

    func processTouchCancelled() {
        switch inputState {
        case .draggingBall, .panningCamera:
            // Treat as touch ended at last known position
            processTouchEnded(at: lastPanPosition)

        case .idle:
            break
        }
    }
}

// MARK: - Gesture Analysis
extension InputController {
    func calculateDragPower(from start: Position, to end: Position, maxDistance: CGFloat = 100.0) -> CGFloat {
        let distance = start.distance(to: end)
        return min(distance / maxDistance, 1.0)
    }

    func calculateDragDirection(from start: Position, to end: Position) -> CGFloat {
        return start.direction(to: end)
    }

    func isValidDragGesture(from start: Position, to end: Position, minimumDistance: CGFloat = 5.0) -> Bool {
        return start.distance(to: end) >= minimumDistance
    }
}

// MARK: - Input State
private enum InputState {
    case idle
    case draggingBall
    case panningCamera
}

// MARK: - Input Validation
extension InputController {
    func validateBallControl(
        touchPosition: Position,
        ballPosition: Position,
        ballVelocity: Velocity
    ) -> BallControlValidation {
        let distance = touchPosition.distance(to: ballPosition)

        guard distance <= ballControlRadius else {
            return .invalid(reason: "Touch too far from ball")
        }

        guard ballVelocity.isStationary else {
            return .invalid(reason: "Ball is moving")
        }

        return .valid
    }
}

enum BallControlValidation {
    case valid
    case invalid(reason: String)

    var isValid: Bool {
        switch self {
        case .valid: return true
        case .invalid: return false
        }
    }
}