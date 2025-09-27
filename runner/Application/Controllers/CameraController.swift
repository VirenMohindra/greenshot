//
//  CameraController.swift
//  runner
//
//  Controller for managing camera state and animations
//

import Foundation
import CoreGraphics

protocol CameraControllerDelegate: AnyObject {
    func cameraController(_ controller: CameraController, didUpdatePosition position: Position, duration: TimeInterval, animationType: CameraAnimationType)
    func cameraController(_ controller: CameraController, didUpdateZoom zoom: CGFloat)
}

class CameraController {
    weak var delegate: CameraControllerDelegate?
    private let settingsController: SettingsController

    // MARK: - Camera State
    private(set) var currentPosition: Position
    private(set) var currentZoom: CGFloat
    private var lastUpdateTime: TimeInterval = 0

    // MARK: - Configuration
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 2.0
    private let updateThrottle: TimeInterval = 0.1 // Limit updates to 10fps

    // MARK: - Course Constraints
    private let courseSize: CGSize
    private let screenSize: CGSize

    init(
        initialPosition: Position,
        initialZoom: CGFloat = 0.6,
        courseSize: CGSize,
        screenSize: CGSize,
        settingsController: SettingsController
    ) {
        self.settingsController = settingsController
        self.currentPosition = initialPosition
        self.currentZoom = max(minZoom, min(maxZoom, initialZoom))
        self.courseSize = courseSize
        self.screenSize = screenSize
    }
}

// MARK: - Position Management
extension CameraController {
    func updatePosition(
        _ newPosition: Position,
        duration: TimeInterval = 0.0,
        animationType: CameraAnimationType = .none,
        force: Bool = false
    ) {
        let currentTime = Date().timeIntervalSinceReferenceDate

        // Throttle updates unless forced
        guard force || (currentTime - lastUpdateTime) >= updateThrottle else {
            return
        }

        let constrainedPosition = constrainPosition(newPosition)

        // Only update if position actually changed
        guard constrainedPosition != currentPosition else {
            return
        }

        currentPosition = constrainedPosition
        lastUpdateTime = currentTime

        delegate?.cameraController(
            self,
            didUpdatePosition: constrainedPosition,
            duration: duration,
            animationType: animationType
        )
    }

    func focusOn(
        position: Position,
        immediate: Bool = false
    ) {
        let cameraSpeed = MainActor.assumeIsolated { settingsController.userPreferences.cameraSpeed }
        let duration = immediate ? 0.0 : (2.0 - cameraSpeed) // Invert so higher setting = faster camera

        updatePosition(
            position,
            duration: duration,
            animationType: immediate ? .none : .easeOut,
            force: true
        )
    }

    private func constrainPosition(_ position: Position) -> Position {
        let padding = screenSize.width * 0.2 / currentZoom
        let minX = padding
        let maxX = courseSize.width - padding
        let minY = padding
        let maxY = courseSize.height - padding

        return Position(
            x: max(minX, min(maxX, position.x)),
            y: max(minY, min(maxY, position.y))
        )
    }
}

// MARK: - Zoom Management
extension CameraController {
    func updateZoom(_ newZoom: CGFloat) {
        let constrainedZoom = max(minZoom, min(maxZoom, newZoom))

        guard constrainedZoom != currentZoom else {
            return
        }

        currentZoom = constrainedZoom

        // Re-constrain position after zoom change
        currentPosition = constrainPosition(currentPosition)

        delegate?.cameraController(self, didUpdateZoom: constrainedZoom)
    }

    func zoomIn(by factor: CGFloat = 1.2) {
        updateZoom(currentZoom * factor)
    }

    func zoomOut(by factor: CGFloat = 0.8) {
        updateZoom(currentZoom * factor)
    }

    func resetZoom() {
        updateZoom(0.6) // Default zoom level
    }
}

// MARK: - Camera Following
extension CameraController {
    func followBall(
        ballPosition: Position,
        ballVelocity: Velocity,
        predictionFactor: CGFloat = 0.5
    ) {
        // Only follow if ball is moving significantly
        guard ballVelocity.magnitude > 10.0 else {
            return
        }

        // Predict where ball will be
        let predictedPosition = Position(
            x: ballPosition.x + ballVelocity.dx * predictionFactor,
            y: ballPosition.y + ballVelocity.dy * predictionFactor
        )

        let cameraSpeed = MainActor.assumeIsolated { settingsController.userPreferences.cameraSpeed }
        let duration = 1.0 - (cameraSpeed * 0.5) // Speed range: 0.5s to 1.0s

        updatePosition(
            predictedPosition,
            duration: duration,
            animationType: .easeOut
        )
    }

    func panBy(delta: Position) {
        let newPosition = Position(
            x: currentPosition.x + delta.x * currentZoom,
            y: currentPosition.y + delta.y * currentZoom
        )

        updatePosition(newPosition, force: true)
    }
}

// MARK: - Camera State Queries
extension CameraController {
    var isAtMinZoom: Bool {
        currentZoom <= minZoom + 0.01
    }

    var isAtMaxZoom: Bool {
        currentZoom >= maxZoom - 0.01
    }

    var canZoomIn: Bool {
        !isAtMaxZoom
    }

    var canZoomOut: Bool {
        !isAtMinZoom
    }

    var visibleArea: CGRect {
        let width = screenSize.width / currentZoom
        let height = screenSize.height / currentZoom

        return CGRect(
            x: currentPosition.x - width / 2,
            y: currentPosition.y - height / 2,
            width: width,
            height: height
        )
    }

    func isPositionVisible(_ position: Position, margin: CGFloat = 50.0) -> Bool {
        let expandedArea = visibleArea.insetBy(dx: -margin, dy: -margin)
        return expandedArea.contains(position.cgPoint)
    }
}