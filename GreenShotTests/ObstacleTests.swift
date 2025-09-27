//
//  ObstacleTests.swift
//  GreenShotTests
//
//  Unit tests for Obstacle entity
//

import Testing
import Foundation
@testable import GreenShot

struct ObstacleTests {

    @Test("Obstacle initializes correctly")
    func testObstacleInitialization() async throws {
        let obstacle = Obstacle(
            type: .bunker,
            position: Position(x: 100, y: 200),
            size: CGSize(width: 40, height: 30)
        )

        #expect(obstacle.type == .bunker, "Obstacle should have correct type")
        #expect(obstacle.position.x == 100, "Obstacle should have correct X position")
        #expect(obstacle.position.y == 200, "Obstacle should have correct Y position")
        #expect(obstacle.size.width == 40, "Obstacle should have correct width")
        #expect(obstacle.size.height == 30, "Obstacle should have correct height")
        #expect(obstacle.id != UUID(), "Obstacle should have unique ID")
    }

    @Test("Obstacle bounds calculation")
    func testBoundsCalculation() async throws {
        let obstacle = Obstacle(
            type: .tree,
            position: Position(x: 100, y: 200),
            size: CGSize(width: 20, height: 20)
        )

        let bounds = obstacle.bounds
        #expect(bounds.origin.x == 90, "Bounds should start at position - half width")
        #expect(bounds.origin.y == 190, "Bounds should start at position - half height")
        #expect(bounds.size.width == 20, "Bounds width should match obstacle width")
        #expect(bounds.size.height == 20, "Bounds height should match obstacle height")
    }

    @Test("Obstacle collision detection")
    func testCollisionDetection() async throws {
        let obstacle = TestFixtures.createTestObstacles()[0] // Bunker at (150, 200)
        let ballPosition = obstacle.position

        #expect(obstacle.contains(ballPosition), "Ball at obstacle center should collide")

        let farPosition = Position(x: obstacle.position.x + 100, y: obstacle.position.y + 100)
        #expect(!obstacle.contains(farPosition), "Ball far from obstacle should not collide")

        let edgePosition = Position(
            x: obstacle.position.x + obstacle.size.width / 2 - 1,
            y: obstacle.position.y
        )
        #expect(obstacle.contains(edgePosition), "Ball at obstacle edge should collide")
    }

    @Test("Obstacle physics properties")
    func testPhysicsProperties() async throws {
        let bunker = Obstacle(type: .bunker, position: Position(x: 0, y: 0), size: CGSize(width: 40, height: 30))
        let water = Obstacle(type: .water, position: Position(x: 0, y: 0), size: CGSize(width: 60, height: 40))
        let tree = Obstacle(type: .tree, position: Position(x: 0, y: 0), size: CGSize(width: 20, height: 20))

        // Test damping values
        #expect(water.damping == 0.0, "Water should have no damping (ball stops)")
        #expect(bunker.damping == 0.3, "Bunker should have high damping")
        #expect(tree.damping == 1.0, "Tree should have no damping (solid collision)")

        // Test restitution values
        #expect(water.restitution == 0.0, "Water should have no restitution")
        #expect(bunker.restitution == 0.1, "Bunker should have low restitution")
        #expect(tree.restitution == 0.6, "Tree should have moderate restitution")

        // Test friction values
        #expect(bunker.friction > water.friction, "Bunker should have more friction than water")
        #expect(tree.friction < bunker.friction, "Tree should have less friction than bunker")
    }

    @Test("Obstacle types and properties")
    func testObstacleTypes() async throws {
        #expect(ObstacleType.water.penaltyStrokes == 1, "Water should have 1 penalty stroke")
        #expect(ObstacleType.bunker.penaltyStrokes == 0, "Bunker should have no penalty strokes")
        #expect(ObstacleType.tree.penaltyStrokes == 0, "Tree should have no penalty strokes")

        #expect(ObstacleType.water.isHazard, "Water should be a hazard")
        #expect(ObstacleType.bunker.isHazard, "Bunker should be a hazard")
        #expect(!ObstacleType.tree.isHazard, "Tree should not be a hazard")

        #expect(!ObstacleType.water.affectsBallPhysics, "Water should not affect ball physics (ball stops)")
        #expect(ObstacleType.bunker.affectsBallPhysics, "Bunker should affect ball physics")
        #expect(ObstacleType.tree.affectsBallPhysics, "Tree should affect ball physics")
    }

    @Test("Obstacle effects on golf ball")
    func testObstacleEffects() async throws {
        let bunker = Obstacle(type: .bunker, position: Position(x: 0, y: 0), size: CGSize(width: 40, height: 30))
        let water = Obstacle(type: .water, position: Position(x: 0, y: 0), size: CGSize(width: 60, height: 40))
        let tree = Obstacle(type: .tree, position: Position(x: 0, y: 0), size: CGSize(width: 20, height: 20))
        let ball = TestFixtures.createTestBall()

        let bunkerEffect = bunker.applyEffect(to: ball)
        let waterEffect = water.applyEffect(to: ball)
        let treeEffect = tree.applyEffect(to: ball)

        // Test different effect types
        switch bunkerEffect {
        case .physics(let damping, let friction):
            #expect(damping == bunker.damping, "Bunker effect should use bunker damping")
            #expect(friction == bunker.friction, "Bunker effect should use bunker friction")
        default:
            #expect(Bool(false), "Bunker should have physics effect")
        }

        switch waterEffect {
        case .penalty(let strokes, let reset):
            #expect(strokes == 1, "Water should have 1 penalty stroke")
            #expect(reset, "Water should reset ball to last position")
        default:
            #expect(Bool(false), "Water should have penalty effect")
        }

        switch treeEffect {
        case .collision(let restitution):
            #expect(restitution == tree.restitution, "Tree effect should use tree restitution")
        default:
            #expect(Bool(false), "Tree should have collision effect")
        }
    }

    @Test("Obstacle distance calculation")
    func testDistanceCalculation() async throws {
        let obstacle = Obstacle(type: .bunker, position: Position(x: 100, y: 100), size: CGSize(width: 40, height: 30))
        let testPosition = Position(x: 103, y: 104)

        let distance = obstacle.distanceTo(testPosition)
        let expectedDistance = obstacle.position.distance(to: testPosition)

        #expect(TestAssertions.assertCGFloatEqual(distance, expectedDistance), "Distance calculation should be accurate")
    }
}