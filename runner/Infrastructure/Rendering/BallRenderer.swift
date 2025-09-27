//
//  BallRenderer.swift
//  runner
//
//  SpriteKit renderer for golf ball appearance and animations
//

import SpriteKit
import UIKit

protocol BallRendererProtocol {
    func createBallNode() -> SKNode
    func updateBallPosition(_ ballNode: SKNode, position: Position)
    func updateBallVisibility(_ ballNode: SKNode, isVisible: Bool)
    func animateBallIntoHole(_ ballNode: SKNode, holePosition: Position, completion: @escaping () -> Void)
    func createResetAnimation(_ ballNode: SKNode, completion: @escaping () -> Void)
    func createTrajectoryPreview(_ positions: [Position]) -> [SKNode]
    func clearTrajectoryPreview(from scene: SKScene)
    func showBallTouchFeedback(_ ballNode: SKNode)
    func showDragFeedback(_ ballNode: SKNode, dragStart: Position, dragEnd: Position)
    func hideBallTouchFeedback(_ ballNode: SKNode)
}

class BallRenderer: BallRendererProtocol {

    func createBallNode() -> SKNode {
        let ballRadius: CGFloat = 8 // Smaller ball - more realistic size
        let ballContainer = SKNode()
        ballContainer.name = "golfBall"

        // Control radius indicator (shows where you can touch)
        let controlRadius = SKShapeNode(circleOfRadius: 80) // Match the ball control radius
        controlRadius.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.2)
        controlRadius.fillColor = .clear
        controlRadius.lineWidth = 1
        controlRadius.zPosition = 5
        controlRadius.name = "controlRadius"
        ballContainer.addChild(controlRadius)

        // Main ball
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = SKColor(red: 0.98, green: 0.98, blue: 0.98, alpha: 1.0)
        ball.strokeColor = SKColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        ball.lineWidth = 1
        ball.zPosition = 10
        ballContainer.addChild(ball)

        // Add dimples for realism
        addDimples(to: ball, radius: ballRadius)

        // Add shadow
        let shadow = SKShapeNode(circleOfRadius: ballRadius + 1)
        shadow.fillColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.15)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 1, y: -1)
        shadow.zPosition = 9
        ballContainer.addChild(shadow)

        return ballContainer
    }

    func updateBallPosition(_ ballNode: SKNode, position: Position) {
        ballNode.position = position.cgPoint
    }

    func updateBallVisibility(_ ballNode: SKNode, isVisible: Bool) {
        ballNode.alpha = isVisible ? 1.0 : 0.0
    }

    func animateBallIntoHole(_ ballNode: SKNode, holePosition: Position, completion: @escaping () -> Void) {
        let shrinkAction = SKAction.scale(to: 0.1, duration: 0.3)
        let moveToHole = SKAction.move(to: holePosition.cgPoint, duration: 0.3)
        let ballAnimation = SKAction.group([shrinkAction, moveToHole])

        ballNode.run(ballAnimation) {
            ballNode.alpha = 0
            completion()
        }
    }

    func createResetAnimation(_ ballNode: SKNode, completion: @escaping () -> Void) {
        let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
        let sequence = SKAction.sequence([scaleUp, scaleDown])

        ballNode.run(sequence) {
            completion()
        }
    }

    // MARK: - Private Helpers
    private func addDimples(to ball: SKShapeNode, radius: CGFloat) {
        let dimpleCount = 12
        let dimpleRadius: CGFloat = 1.5

        for i in 0..<dimpleCount {
            let angle = (CGFloat(i) / CGFloat(dimpleCount)) * 2 * .pi
            let dimpleDistance = radius * 0.7
            let x = cos(angle) * dimpleDistance
            let y = sin(angle) * dimpleDistance

            let dimple = SKShapeNode(circleOfRadius: dimpleRadius)
            dimple.position = CGPoint(x: x, y: y)
            dimple.fillColor = SKColor(red: 0.90, green: 0.90, blue: 0.90, alpha: 0.6)
            dimple.strokeColor = .clear
            ball.addChild(dimple)
        }
    }
}

// MARK: - Ball Physics Visualization
extension BallRenderer {
    func createTrajectoryPreview(_ positions: [Position]) -> [SKNode] {
        var previewNodes: [SKNode] = []

        for (index, position) in positions.enumerated() {
            let dot = SKShapeNode(circleOfRadius: 2)
            dot.fillColor = .white
            dot.strokeColor = .gray
            dot.lineWidth = 1
            dot.alpha = CGFloat(positions.count - index) / CGFloat(positions.count)
            dot.position = position.cgPoint
            dot.zPosition = 5
            dot.name = "trajectoryDot"
            previewNodes.append(dot)
        }

        return previewNodes
    }

    func clearTrajectoryPreview(from scene: SKScene) {
        scene.children.filter { $0.name == "trajectoryDot" }.forEach { $0.removeFromParent() }
    }

    func createPowerIndicator(
        at ballPosition: Position,
        direction: CGFloat,
        power: CGFloat
    ) -> SKNode? {
        guard power > 0 else { return nil }

        let startAngle = direction - .pi / 6
        let endAngle = direction + .pi / 6

        let path = UIBezierPath(
            arcCenter: ballPosition.cgPoint,
            radius: 30,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: true
        )

        let powerIndicator = SKShapeNode(path: path.cgPath)
        powerIndicator.strokeColor = SKColor(red: 1.0, green: 1.0 - power, blue: 0, alpha: 1.0)
        powerIndicator.lineWidth = 5
        powerIndicator.zPosition = 8
        powerIndicator.name = "powerIndicator"

        return powerIndicator
    }

    func clearPowerIndicator(from scene: SKScene) {
        scene.childNode(withName: "powerIndicator")?.removeFromParent()
    }

    // MARK: - Touch Tracking Visualization
    func showBallTouchFeedback(_ ballNode: SKNode) {
        // Remove existing touch feedback
        ballNode.childNode(withName: "touchRing")?.removeFromParent()

        // Create simple touch ring - no animations to avoid interference
        let touchRing = SKShapeNode(circleOfRadius: 30)
        touchRing.strokeColor = SKColor(red: 0.0, green: 1.0, blue: 0.0, alpha: 0.8)
        touchRing.fillColor = .clear
        touchRing.lineWidth = 4
        touchRing.zPosition = 8
        touchRing.name = "touchRing"

        ballNode.addChild(touchRing)
        print("🎯 Touch feedback: Ball control ring activated")
    }

    func showDragFeedback(_ ballNode: SKNode, dragStart: Position, dragEnd: Position) {
        // Remove existing drag line
        ballNode.childNode(withName: "dragLine")?.removeFromParent()

        // Create drag line
        let path = CGMutablePath()
        path.move(to: CGPoint.zero) // Relative to ball position
        let relative = Position(x: dragEnd.x - dragStart.x, y: dragEnd.y - dragStart.y)
        path.addLine(to: relative.cgPoint)

        let dragLine = SKShapeNode(path: path)
        dragLine.strokeColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)
        dragLine.lineWidth = 4
        dragLine.zPosition = 7
        dragLine.name = "dragLine"

        // Add arrow at end
        let arrowPath = createArrowPath(at: relative.cgPoint)
        let arrow = SKShapeNode(path: arrowPath)
        arrow.fillColor = SKColor(red: 1.0, green: 0.6, blue: 0.0, alpha: 0.9)
        arrow.strokeColor = .clear
        arrow.zPosition = 7
        dragLine.addChild(arrow)

        ballNode.addChild(dragLine)

        let distance = dragStart.distance(to: dragEnd)
        print("🏌️ Drag feedback: Distance \(Int(distance)), Direction: \(Int(dragStart.direction(to: dragEnd) * 180 / .pi))°")
    }

    func hideBallTouchFeedback(_ ballNode: SKNode) {
        ballNode.childNode(withName: "touchRing")?.removeFromParent()
        ballNode.childNode(withName: "dragLine")?.removeFromParent()
        print("🚫 Touch feedback: Ball control indicators hidden")
    }

    private func createArrowPath(at position: CGPoint) -> CGPath {
        let path = CGMutablePath()
        let arrowSize: CGFloat = 8

        // Arrow pointing in direction of the line
        path.move(to: CGPoint(x: position.x - arrowSize, y: position.y - arrowSize/2))
        path.addLine(to: position)
        path.addLine(to: CGPoint(x: position.x - arrowSize, y: position.y + arrowSize/2))
        path.closeSubpath()

        return path
    }
}