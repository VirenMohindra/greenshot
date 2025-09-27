//
//  UpdateCameraUseCaseTests.swift
//  GreenShotTests
//
//  Unit tests for UpdateCameraUseCase
//

import Testing
import Foundation
@testable import GreenShot

struct UpdateCameraUseCaseTests {

    @Test("UpdateCameraUseCase follows ball correctly")
    func testFollowBall() async throws {
        let useCase = UpdateCameraUseCase()
        let cameraPosition = Position(x: 100, y: 200)
        let ballPosition = Position(x: 300, y: 400)
        let ballVelocity = Velocity(dx: 5.0, dy: 3.0)
        let courseSize = CGSize(width: 800, height: 1200)
        let screenSize = CGSize(width: 375, height: 812)

        let result = useCase.followBall(
            cameraPosition: cameraPosition,
            ballPosition: ballPosition,
            ballVelocity: ballVelocity,
            courseSize: courseSize,
            screenSize: screenSize
        )

        #expect(result.shouldUpdate, "Following ball should trigger update")
        switch result {
        case .update(let newPosition, let duration, let animationType):
            #expect(duration > 0, "Animation should have duration")
            #expect(animationType == .easeOut, "Should use easeOut animation")
        case .noUpdate:
            #expect(Bool(false), "Should not return noUpdate for moving ball")
        }
    }

    @Test("UpdateCameraUseCase handles zoom updates")
    func testZoomUpdates() async throws {
        let useCase = UpdateCameraUseCase()
        let currentZoom: CGFloat = 0.5
        let zoomDelta: CGFloat = 0.3

        let result = useCase.handleZoom(currentZoom: currentZoom, zoomDelta: zoomDelta)

        #expect(result.shouldUpdate, "Zoom update should succeed")
        switch result {
        case .update(let newZoom):
            #expect(newZoom > currentZoom, "Zoom should increase")
            #expect(newZoom <= 2.0, "Zoom should not exceed maximum")
        case .noChange:
            #expect(Bool(false), "Should update zoom with valid delta")
        }
    }

    @Test("UpdateCameraUseCase focuses on position")
    func testFocusOnPosition() async throws {
        let useCase = UpdateCameraUseCase()
        let targetPosition = Position(x: 400, y: 600)
        let courseSize = CGSize(width: 800, height: 1200)
        let screenSize = CGSize(width: 375, height: 812)

        let result = useCase.focusOnPosition(
            targetPosition: targetPosition,
            courseSize: courseSize,
            screenSize: screenSize,
            immediate: true
        )

        #expect(result.shouldUpdate, "Focus should succeed")
        switch result {
        case .update(let newPosition, let duration, let animationType):
            #expect(duration == 0, "Immediate focus should have zero duration")
            #expect(animationType == .easeOut, "Should use easeOut animation")
        case .noUpdate:
            #expect(Bool(false), "Focus should always trigger update")
        }
    }

    @Test("UpdateCameraUseCase handles pan gestures")
    func testHandlePan() async throws {
        let useCase = UpdateCameraUseCase()
        let currentPosition = Position(x: 200, y: 300)
        let panDelta = Position(x: 50, y: -30)
        let courseSize = CGSize(width: 800, height: 1200)
        let screenSize = CGSize(width: 375, height: 812)

        let result = useCase.handlePan(
            currentPosition: currentPosition,
            panDelta: panDelta,
            courseSize: courseSize,
            screenSize: screenSize
        )

        #expect(result.shouldUpdate, "Pan should trigger update")
        switch result {
        case .update(let newPosition, let duration, let animationType):
            #expect(duration == 0, "Pan should be immediate")
            #expect(animationType == .none, "Pan should not animate")
            #expect(newPosition.x != currentPosition.x, "Position should change")
        case .noUpdate:
            #expect(Bool(false), "Pan should always trigger update")
        }
    }

    @Test("UpdateCameraUseCase handles stationary ball")
    func testStationaryBall() async throws {
        let useCase = UpdateCameraUseCase()
        let cameraPosition = Position(x: 100, y: 200)
        let ballPosition = Position(x: 300, y: 400)
        let stationaryVelocity = Velocity(dx: 0.001, dy: 0.001) // Below stationary threshold
        let courseSize = CGSize(width: 800, height: 1200)
        let screenSize = CGSize(width: 375, height: 812)

        let result = useCase.followBall(
            cameraPosition: cameraPosition,
            ballPosition: ballPosition,
            ballVelocity: stationaryVelocity,
            courseSize: courseSize,
            screenSize: screenSize
        )

        #expect(!result.shouldUpdate, "Stationary ball should not trigger camera follow")
        switch result {
        case .noUpdate:
            break // Expected
        case .update:
            #expect(Bool(false), "Should not update camera for stationary ball")
        }
    }

    @Test("UpdateCameraUseCase constrains zoom bounds")
    func testZoomBounds() async throws {
        let useCase = UpdateCameraUseCase()

        // Test zoom beyond maximum
        let maxZoomResult = useCase.handleZoom(currentZoom: 1.8, zoomDelta: 0.5)
        switch maxZoomResult {
        case .update(let newZoom):
            #expect(newZoom <= 2.0, "Zoom should be constrained to maximum")
        case .noChange:
            break // Valid if already at max
        }

        // Test zoom below minimum
        let minZoomResult = useCase.handleZoom(currentZoom: 0.7, zoomDelta: -0.5)
        switch minZoomResult {
        case .update(let newZoom):
            #expect(newZoom >= 0.5, "Zoom should be constrained to minimum")
        case .noChange:
            break // Valid if already at min
        }
    }
}