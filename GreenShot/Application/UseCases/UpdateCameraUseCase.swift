//
//  UpdateCameraUseCase.swift
//  GreenShot
//
//  Use case for managing camera positioning and movement
//

import Foundation
import CoreGraphics

protocol UpdateCameraUseCaseProtocol {
    func followBall(
        cameraPosition: Position,
        ballPosition: Position,
        ballVelocity: Velocity,
        courseSize: CGSize,
        screenSize: CGSize
    ) -> CameraUpdateResult

    func focusOnPosition(
        targetPosition: Position,
        courseSize: CGSize,
        screenSize: CGSize,
        immediate: Bool
    ) -> CameraUpdateResult

    func handleZoom(currentZoom: CGFloat, zoomDelta: CGFloat) -> CameraZoomResult
    func handlePan(currentPosition: Position, panDelta: Position, courseSize: CGSize, screenSize: CGSize) -> CameraUpdateResult
}

class UpdateCameraUseCase: UpdateCameraUseCaseProtocol {
    private let minZoom: CGFloat = 0.5
    private let maxZoom: CGFloat = 2.0

    func followBall(
        cameraPosition: Position,
        ballPosition: Position,
        ballVelocity: Velocity,
        courseSize: CGSize,
        screenSize: CGSize
    ) -> CameraUpdateResult {
        // Only follow if ball is moving
        guard !ballVelocity.isStationary else {
            return .noUpdate
        }

        // Calculate target position with some prediction
        let predictionFactor: CGFloat = 0.5
        let predictedPosition = Position(
            x: ballPosition.x + ballVelocity.dx * predictionFactor,
            y: ballPosition.y + ballVelocity.dy * predictionFactor
        )

        return focusOnPosition(
            targetPosition: predictedPosition,
            courseSize: courseSize,
            screenSize: screenSize,
            immediate: false
        )
    }

    func focusOnPosition(
        targetPosition: Position,
        courseSize: CGSize,
        screenSize: CGSize,
        immediate: Bool
    ) -> CameraUpdateResult {
        // Constrain target position to course bounds
        let padding = screenSize.width * 0.2
        let constrainedX = max(padding, min(courseSize.width - padding, targetPosition.x))
        let constrainedY = max(padding, min(courseSize.height - padding, targetPosition.y))

        let finalPosition = Position(x: constrainedX, y: constrainedY)

        return .update(
            newPosition: finalPosition,
            duration: immediate ? 0.0 : 1.0,
            animationType: .easeOut
        )
    }

    func handleZoom(currentZoom: CGFloat, zoomDelta: CGFloat) -> CameraZoomResult {
        let newZoom = max(minZoom, min(maxZoom, currentZoom + zoomDelta))

        if newZoom != currentZoom {
            return .update(newZoom: newZoom)
        } else {
            return .noChange
        }
    }

    func handlePan(
        currentPosition: Position,
        panDelta: Position,
        courseSize: CGSize,
        screenSize: CGSize
    ) -> CameraUpdateResult {
        let newPosition = Position(
            x: currentPosition.x + panDelta.x,
            y: currentPosition.y + panDelta.y
        )

        // Constrain to course bounds
        let padding = screenSize.width * 0.2
        let constrainedX = max(padding, min(courseSize.width - padding, newPosition.x))
        let constrainedY = max(padding, min(courseSize.height - padding, newPosition.y))

        let finalPosition = Position(x: constrainedX, y: constrainedY)

        return .update(
            newPosition: finalPosition,
            duration: 0.0,
            animationType: .none
        )
    }
}

// MARK: - Result Types
enum CameraUpdateResult {
    case update(newPosition: Position, duration: TimeInterval, animationType: CameraAnimationType)
    case noUpdate

    var shouldUpdate: Bool {
        switch self {
        case .update: return true
        case .noUpdate: return false
        }
    }
}

enum CameraZoomResult {
    case update(newZoom: CGFloat)
    case noChange

    var shouldUpdate: Bool {
        switch self {
        case .update: return true
        case .noChange: return false
        }
    }
}

enum CameraAnimationType {
    case none
    case easeIn
    case easeOut
    case easeInOut
}