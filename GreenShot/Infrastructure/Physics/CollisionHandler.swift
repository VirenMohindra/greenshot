//
//  CollisionHandler.swift
//  GreenShot
//
//  SpriteKit collision detection and response handler
//

import SpriteKit
import Foundation

protocol CollisionHandlerDelegate: AnyObject {
    func collisionHandler(_ handler: CollisionHandler, ballEnteredHole ball: GolfBall, at position: Position)
    func collisionHandler(_ handler: CollisionHandler, ballHitObstacle ball: GolfBall, obstacle: Obstacle, effect: ObstacleEffect)
    func collisionHandler(_ handler: CollisionHandler, ballWentOutOfBounds ball: GolfBall)
}

class CollisionHandler: NSObject {
    weak var delegate: CollisionHandlerDelegate?
    private let physicsService: PhysicsServiceProtocol

    // Reference to game objects for collision resolution
    private weak var golfBall: GolfBall?
    private var obstacleMap: [String: Obstacle] = [:] // Node name -> Obstacle

    init(physicsService: PhysicsServiceProtocol) {
        self.physicsService = physicsService
        super.init()
    }

    func configure(ball: GolfBall, obstacles: [Obstacle]) {
        self.golfBall = ball

        // Build obstacle lookup map
        obstacleMap.removeAll()
        for obstacle in obstacles {
            obstacleMap["obstacle_\(obstacle.id.uuidString)"] = obstacle
        }
    }
}

// MARK: - SKPhysicsContactDelegate
extension CollisionHandler: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        let collision = contact.bodyA.categoryBitMask | contact.bodyB.categoryBitMask

        if collision == PhysicsWorld.PhysicsCategory.ball | PhysicsWorld.PhysicsCategory.hole {
            handleBallHoleContact(contact)
        } else if collision == PhysicsWorld.PhysicsCategory.ball | PhysicsWorld.PhysicsCategory.obstacle {
            handleBallObstacleContact(contact)
        } else if collision == PhysicsWorld.PhysicsCategory.ball | PhysicsWorld.PhysicsCategory.outOfBounds {
            handleBallOutOfBoundsContact()
        } else if collision == PhysicsWorld.PhysicsCategory.ball | PhysicsWorld.PhysicsCategory.holeDampening {
            handleBallHoleDampeningContact(contact)
        }
    }

    private func handleBallHoleContact(_ contact: SKPhysicsContact) {
        guard let ball = golfBall else { return }

        // Check if ball is moving slowly enough to go in
        let speed = ball.velocity.magnitude
        if speed < Constants.Ball.stationaryThreshold {
            delegate?.collisionHandler(self, ballEnteredHole: ball, at: ball.position)
        }
    }

    private func handleBallObstacleContact(_ contact: SKPhysicsContact) {
        guard let ball = golfBall else { return }

        // Determine which node is the obstacle
        let obstacleNode: SKNode?
        if contact.bodyA.categoryBitMask == PhysicsWorld.PhysicsCategory.obstacle {
            obstacleNode = contact.bodyA.node
        } else {
            obstacleNode = contact.bodyB.node
        }

        guard let node = obstacleNode,
              let nodeName = node.name,
              let obstacle = obstacleMap[nodeName] else { return }

        // Apply obstacle effect
        let effect = obstacle.applyEffect(to: ball)

        // Apply physics response based on obstacle type
        applyObstaclePhysics(ball: ball, obstacle: obstacle, effect: effect)

        // Notify delegate
        delegate?.collisionHandler(self, ballHitObstacle: ball, obstacle: obstacle, effect: effect)
    }

    private func handleBallHoleDampeningContact(_ contact: SKPhysicsContact) {
        guard let ball = golfBall else { return }

        // Apply gradual dampening when ball enters hole area
        let dampeningFactor: CGFloat = 0.85 // Slow down the ball by 15%
        let currentVelocity = ball.velocity
        let newVelocity = Velocity(
            dx: currentVelocity.dx * dampeningFactor,
            dy: currentVelocity.dy * dampeningFactor
        )
        ball.updateVelocity(newVelocity)

        print("🕳️ Ball entering hole dampening area - velocity reduced")
    }

    private func handleBallOutOfBoundsContact() {
        guard let ball = golfBall else { return }
        delegate?.collisionHandler(self, ballWentOutOfBounds: ball)
    }

    private func applyObstaclePhysics(ball: GolfBall, obstacle: Obstacle, effect: ObstacleEffect) {
        switch effect {
        case .penalty(_, let resetToLastPosition):
            if resetToLastPosition {
                ball.stop()
            }

        case .physics(let damping, _):
            ball.applyDamping(damping)

        case .collision(_):
            // Calculate collision response
            let newVelocity = physicsService.calculateCollisionResponse(
                ballVelocity: ball.velocity,
                obstacle: obstacle
            )
            ball.updateVelocity(newVelocity)

        case .none:
            break
        }
    }
}

// MARK: - Physics Utilities
extension CollisionHandler {
    func checkForCollisions(ballPosition: Position, ballRadius: CGFloat = 8.0) -> [Obstacle] {
        var collidingObstacles: [Obstacle] = []

        for obstacle in obstacleMap.values {
            if physicsService.isColliding(
                ballPosition: ballPosition,
                ballRadius: ballRadius,
                obstacle: obstacle
            ) {
                collidingObstacles.append(obstacle)
            }
        }

        return collidingObstacles
    }

    func isPositionInBounds(_ position: Position, worldSize: CGSize) -> Bool {
        let margin: CGFloat = 50
        let bounds = CGRect(
            x: margin,
            y: margin,
            width: worldSize.width - margin * 2,
            height: worldSize.height - margin * 2
        )
        return bounds.contains(position.cgPoint)
    }
}