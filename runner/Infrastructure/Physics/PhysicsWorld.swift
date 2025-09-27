//
//  PhysicsWorld.swift
//  runner
//
//  SpriteKit physics world setup and configuration
//

import SpriteKit
import Foundation

protocol PhysicsWorldProtocol {
    func setupPhysics(in scene: SKScene, worldSize: CGSize)
    func createBallPhysicsBody() -> SKPhysicsBody
    func createObstaclePhysicsBody(for obstacle: Obstacle) -> SKPhysicsBody
    func createHolePhysicsBody() -> SKPhysicsBody
    func createHoleDampeningArea() -> SKPhysicsBody
}

class PhysicsWorld: PhysicsWorldProtocol {

    // Physics categories
    struct PhysicsCategory {
        static let none: UInt32 = 0
        static let ball: UInt32 = 0x1 << 0
        static let hole: UInt32 = 0x1 << 1
        static let obstacle: UInt32 = 0x1 << 2
        static let boundary: UInt32 = 0x1 << 3
        static let outOfBounds: UInt32 = 0x1 << 4
        static let holeDampening: UInt32 = 0x1 << 5
    }

    func setupPhysics(in scene: SKScene, worldSize: CGSize) {
        // Configure physics world
        scene.physicsWorld.gravity = CGVector(dx: 0, dy: 0) // Top-down view
        scene.physicsWorld.speed = 1.0

        // Create world boundary
        let courseFrame = CGRect(origin: .zero, size: worldSize)
        let boundary = SKPhysicsBody(edgeLoopFrom: courseFrame)
        boundary.categoryBitMask = PhysicsCategory.boundary
        boundary.friction = 0.3
        scene.physicsBody = boundary

        // Create out-of-bounds sensors
        createOutOfBoundsSensors(in: scene, worldSize: worldSize)
    }

    func createBallPhysicsBody() -> SKPhysicsBody {
        let ballBody = SKPhysicsBody(circleOfRadius: 8) // Smaller radius to match visual
        ballBody.mass = 0.15 // Heavier ball for better control and realistic physics
        ballBody.restitution = 0.2 // Less bouncy for more realistic behavior
        ballBody.linearDamping = 2.5 // Higher damping to stop rolling more naturally
        ballBody.angularDamping = 1.2 // More angular damping for realistic spin
        ballBody.friction = 0.6 // Higher friction for better stopping power
        ballBody.categoryBitMask = PhysicsCategory.ball
        ballBody.contactTestBitMask = PhysicsCategory.hole | PhysicsCategory.obstacle | PhysicsCategory.outOfBounds | PhysicsCategory.holeDampening
        ballBody.collisionBitMask = PhysicsCategory.boundary | PhysicsCategory.obstacle
        ballBody.isDynamic = true
        return ballBody
    }

    func createObstaclePhysicsBody(for obstacle: Obstacle) -> SKPhysicsBody {
        let physicsBody: SKPhysicsBody

        switch obstacle.type {
        case .tree:
            // Circular collision for trees
            physicsBody = SKPhysicsBody(circleOfRadius: obstacle.size.width / 2)
            physicsBody.collisionBitMask = PhysicsCategory.ball

        case .water, .bunker, .rough:
            // Rectangular trigger zones
            physicsBody = SKPhysicsBody(rectangleOf: obstacle.size)
            physicsBody.collisionBitMask = PhysicsCategory.none
        }

        physicsBody.isDynamic = false
        physicsBody.categoryBitMask = PhysicsCategory.obstacle
        physicsBody.contactTestBitMask = PhysicsCategory.ball
        physicsBody.friction = obstacle.friction
        physicsBody.restitution = obstacle.restitution

        return physicsBody
    }

    func createHolePhysicsBody() -> SKPhysicsBody {
        let holeBody = SKPhysicsBody(circleOfRadius: 12) // Slightly smaller for more precise entry
        holeBody.isDynamic = false
        holeBody.categoryBitMask = PhysicsCategory.hole
        holeBody.contactTestBitMask = PhysicsCategory.ball
        holeBody.collisionBitMask = PhysicsCategory.none
        return holeBody
    }

    func createHoleDampeningArea() -> SKPhysicsBody {
        // Create a larger dampening area around the hole
        let dampeningBody = SKPhysicsBody(circleOfRadius: 25)
        dampeningBody.isDynamic = false
        dampeningBody.categoryBitMask = PhysicsCategory.holeDampening
        dampeningBody.contactTestBitMask = PhysicsCategory.ball
        dampeningBody.collisionBitMask = PhysicsCategory.none
        return dampeningBody
    }

    // MARK: - Private Helpers
    private func createOutOfBoundsSensors(in scene: SKScene, worldSize: CGSize) {
        scene.childNode(withName: "outOfBounds")?.removeFromParent()

        let outOfBoundsContainer = SKNode()
        outOfBoundsContainer.name = "outOfBounds"

        let outOfBoundsMargin: CGFloat = 50
        let playableArea = CGRect(
            x: outOfBoundsMargin,
            y: outOfBoundsMargin,
            width: worldSize.width - (outOfBoundsMargin * 2),
            height: worldSize.height - (outOfBoundsMargin * 2)
        )

        let sensorThickness: CGFloat = 20

        // Create sensors for each edge
        let sensors = [
            // Top
            (CGRect(x: 0, y: playableArea.maxY, width: worldSize.width, height: sensorThickness),
             CGPoint(x: worldSize.width/2, y: playableArea.maxY + sensorThickness/2)),
            // Bottom
            (CGRect(x: 0, y: playableArea.minY - sensorThickness, width: worldSize.width, height: sensorThickness),
             CGPoint(x: worldSize.width/2, y: playableArea.minY - sensorThickness/2)),
            // Left
            (CGRect(x: playableArea.minX - sensorThickness, y: 0, width: sensorThickness, height: worldSize.height),
             CGPoint(x: playableArea.minX - sensorThickness/2, y: worldSize.height/2)),
            // Right
            (CGRect(x: playableArea.maxX, y: 0, width: sensorThickness, height: worldSize.height),
             CGPoint(x: playableArea.maxX + sensorThickness/2, y: worldSize.height/2))
        ]

        for (rect, center) in sensors {
            let sensor = SKShapeNode(rect: rect)
            sensor.alpha = 0 // Invisible

            let physics = SKPhysicsBody(rectangleOf: rect.size, center: center)
            physics.isDynamic = false
            physics.categoryBitMask = PhysicsCategory.outOfBounds
            physics.contactTestBitMask = PhysicsCategory.ball
            physics.collisionBitMask = PhysicsCategory.none
            sensor.physicsBody = physics

            outOfBoundsContainer.addChild(sensor)
        }

        scene.addChild(outOfBoundsContainer)
    }
}