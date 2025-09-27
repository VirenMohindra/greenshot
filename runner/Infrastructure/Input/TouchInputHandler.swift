//
//  TouchInputHandler.swift
//  runner
//
//  SpriteKit touch input processing and gesture recognition
//

import SpriteKit
import UIKit

protocol TouchInputHandlerDelegate: AnyObject {
    func touchInputHandler(_ handler: TouchInputHandler, didStartDrag at: Position, ballPosition: Position)
    func touchInputHandler(_ handler: TouchInputHandler, didUpdateDrag to: Position, from start: Position)
    func touchInputHandler(_ handler: TouchInputHandler, didEndDrag at: Position, from start: Position, power: CGFloat)
    func touchInputHandler(_ handler: TouchInputHandler, didCancelDrag: Void)
    func touchInputHandler(_ handler: TouchInputHandler, didTapReset: Void)
    func touchInputHandler(_ handler: TouchInputHandler, didStartPan at: Position)
    func touchInputHandler(_ handler: TouchInputHandler, didUpdatePan to: Position, delta: Position)
    func touchInputHandler(_ handler: TouchInputHandler, didEndPan: Void)
}

class TouchInputHandler {
    weak var delegate: TouchInputHandlerDelegate?
    private let inputController: InputController

    // Touch state
    private var currentTouches: [UITouch: Position] = [:]
    private var currentBallPosition: Position = .zero

    init() {
        self.inputController = InputController()
        setupInputController()
    }

    private func setupInputController() {
        inputController.delegate = self
    }
}

// MARK: - SKScene Touch Handling
extension TouchInputHandler {
    func handleTouchesBegan(_ touches: Set<UITouch>, in scene: SKScene, ballPosition: Position, ballVelocity: Velocity, resetButtonPosition: Position?) {
        guard let touch = touches.first else { return }

        let location = Position(touch.location(in: scene))
        currentTouches[touch] = location

        // Store ball position for use in delegate callbacks
        currentBallPosition = ballPosition

        print("🎯 TouchInputHandler: Touch at \(location), Ball at \(ballPosition)")

        inputController.processTouchBegan(
            at: location,
            ballPosition: ballPosition,
            ballVelocity: ballVelocity,
            resetButtonPosition: resetButtonPosition
        )
    }

    func handleTouchesMoved(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            let location = Position(touch.location(in: scene))
            currentTouches[touch] = location
            inputController.processTouchMoved(to: location)
        }
    }

    func handleTouchesEnded(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            let location = Position(touch.location(in: scene))
            inputController.processTouchEnded(at: location)
            currentTouches.removeValue(forKey: touch)
        }
    }

    func handleTouchesCancelled(_ touches: Set<UITouch>, in scene: SKScene) {
        for touch in touches {
            currentTouches.removeValue(forKey: touch)
        }
        inputController.processTouchCancelled()
    }
}

// MARK: - InputControllerDelegate
extension TouchInputHandler: InputControllerDelegate {
    func inputController(_ controller: InputController, didStartDrag at: Position) {
        // Pass the touch position and the actual ball position (stored from touch began)
        delegate?.touchInputHandler(self, didStartDrag: at, ballPosition: currentBallPosition)
    }

    func inputController(_ controller: InputController, didUpdateDrag to: Position, from start: Position) {
        delegate?.touchInputHandler(self, didUpdateDrag: to, from: start)
    }

    func inputController(_ controller: InputController, didEndDrag at: Position, from start: Position) {
        let power = controller.calculateDragPower(from: start, to: at)
        delegate?.touchInputHandler(self, didEndDrag: at, from: start, power: power)
    }

    func inputController(_ controller: InputController, didCancelDrag: Void) {
        delegate?.touchInputHandler(self, didCancelDrag: ())
    }

    func inputController(_ controller: InputController, didTapResetButton: Void) {
        delegate?.touchInputHandler(self, didTapReset: ())
    }

    func inputController(_ controller: InputController, didStartPan at: Position) {
        delegate?.touchInputHandler(self, didStartPan: at)
    }

    func inputController(_ controller: InputController, didUpdatePan to: Position, delta: Position) {
        delegate?.touchInputHandler(self, didUpdatePan: to, delta: delta)
    }

    func inputController(_ controller: InputController, didEndPan: Void) {
        delegate?.touchInputHandler(self, didEndPan: ())
    }
}

// MARK: - Gesture Analysis
extension TouchInputHandler {
    func validateBallTouch(
        touchPosition: Position,
        ballPosition: Position,
        ballVelocity: Velocity
    ) -> BallControlValidation {
        return inputController.validateBallControl(
            touchPosition: touchPosition,
            ballPosition: ballPosition,
            ballVelocity: ballVelocity
        )
    }

    func calculateShotMetrics(from start: Position, to end: Position) -> ShotMetrics {
        let power = inputController.calculateDragPower(from: start, to: end)
        let direction = inputController.calculateDragDirection(from: start, to: end)
        let isValid = inputController.isValidDragGesture(from: start, to: end)

        return ShotMetrics(
            power: power,
            direction: direction,
            isValidGesture: isValid,
            distance: start.distance(to: end)
        )
    }
}

// MARK: - Supporting Types
struct ShotMetrics {
    let power: CGFloat
    let direction: CGFloat
    let isValidGesture: Bool
    let distance: CGFloat
}