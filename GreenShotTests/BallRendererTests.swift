//
//  BallRendererTests.swift
//  GreenShotTests
//
//  Unit tests for BallRenderer
//

import Testing
import Foundation
import SpriteKit
@testable import GreenShot

struct BallRendererTests {

    @Test("BallRenderer creates ball node correctly")
    func testCreateBallNode() async throws {
        let settingsController = MockSettingsController(persistenceService: MockServiceFactory.createMockPersistenceService())
        let renderer = BallRenderer(settingsController: settingsController)

        let ballNode = renderer.createBallNode()

        #expect(ballNode.name == "golfBall", "Ball node should have correct name")
        #expect(ballNode.children.count > 0, "Ball node should have child components")
    }

    @Test("BallRenderer updates ball position")
    func testUpdateBallPosition() async throws {
        let settingsController = MockSettingsController(persistenceService: MockServiceFactory.createMockPersistenceService())
        let renderer = BallRenderer(settingsController: settingsController)

        let ballNode = renderer.createBallNode()
        let newPosition = Position(x: 150, y: 200)

        renderer.updateBallPosition(ballNode, position: newPosition)

        #expect(ballNode.position == newPosition.cgPoint, "Ball position should be updated")
    }

    @Test("BallRenderer creates trajectory preview")
    @MainActor
    func testTrajectoryPreview() async throws {
        let settingsController = MockSettingsController(persistenceService: MockServiceFactory.createMockPersistenceService())
        settingsController.setShowTrajectoryPreview(true)

        let renderer = BallRenderer(settingsController: settingsController)
        let positions = [
            Position(x: 0, y: 0),
            Position(x: 50, y: 25),
            Position(x: 100, y: 40)
        ]

        let previewNodes = renderer.createTrajectoryPreview(positions)

        #expect(previewNodes.count == positions.count, "Should create preview node for each position")
        #expect(previewNodes.allSatisfy { $0.name == "trajectoryDot" }, "All nodes should have correct name")
    }

    @Test("BallRenderer respects settings for trajectory preview")
    @MainActor
    func testTrajectoryPreviewSettings() async throws {
        let settingsController = MockSettingsController(persistenceService: MockServiceFactory.createMockPersistenceService())
        settingsController.setShowTrajectoryPreview(false)

        let renderer = BallRenderer(settingsController: settingsController)
        let positions = [Position(x: 0, y: 0), Position(x: 100, y: 100)]

        let previewNodes = renderer.createTrajectoryPreview(positions)

        #expect(previewNodes.isEmpty, "Should not create preview when disabled in settings")
    }

    @Test("BallRenderer creates ball trail efficiently")
    @MainActor
    func testBallTrailPerformance() async throws {
        let settingsController = MockSettingsController(persistenceService: MockServiceFactory.createMockPersistenceService())
        settingsController.setEnableTrailEffects(true)

        let renderer = BallRenderer(settingsController: settingsController)
        let scene = SKScene()

        let positions = (0..<30).map { Position(x: CGFloat($0 * 10), y: CGFloat($0 * 5)) }

        let (_, elapsed) = PerformanceTestUtilities.measureExecutionTime {
            for _ in 0..<10 {
                renderer.createBallTrail(from: positions, in: scene)
            }
        }

        #expect(elapsed < 0.01, "Ball trail creation should be fast with optimization")
    }
}

// Mock settings controller
@MainActor
class MockSettingsController: SettingsController {
    private var mockShowTrajectoryPreview = true
    private var mockEnableTrailEffects = true
    private var mockShowControlRadius = true

    nonisolated override init(persistenceService: PersistenceServiceProtocol) {
        super.init(persistenceService: persistenceService)
        Task { @MainActor in
            updateMockPreferences()
        }
    }

    func setShowTrajectoryPreview(_ value: Bool) {
        mockShowTrajectoryPreview = value
        Task { @MainActor in
            updateMockPreferences()
        }
    }

    func setEnableTrailEffects(_ value: Bool) {
        mockEnableTrailEffects = value
        Task { @MainActor in
            updateMockPreferences()
        }
    }

    func setShowControlRadius(_ value: Bool) {
        mockShowControlRadius = value
        Task { @MainActor in
            updateMockPreferences()
        }
    }

    private func updateMockPreferences() {
        userPreferences = UserPreferences(
            soundEnabled: true,
            musicEnabled: true,
            hapticFeedback: true,
            showTrajectoryPreview: mockShowTrajectoryPreview,
            autoZoomOnShot: true,
            showControlRadius: mockShowControlRadius,
            courseDifficulty: "Medium",
            courseLength: "18 Holes",
            obstacleFrequency: "Normal",
            showCelebrations: true,
            enableTrailEffects: mockEnableTrailEffects,
            cameraSpeed: 0.5,
            highContrastMode: false,
            reducedMotion: false,
            largerText: false,
            lastUpdated: Date()
        )
    }
}