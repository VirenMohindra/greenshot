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
    func createBallTrail(from positions: [Position], in scene: SKScene)
    func clearBallTrail(from scene: SKScene)
}

class BallRenderer: BallRendererProtocol {

    func createBallNode() -> SKNode {
        let ballRadius = Constants.Ball.radius
        let ballContainer = SKNode()
        ballContainer.name = "golfBall"

        // Control radius indicator (shows where you can touch)
        let controlRadius = SKShapeNode(circleOfRadius: Constants.Ball.controlRadius)
        controlRadius.strokeColor = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: Constants.Colors.UI.controlRadiusAlpha)
        controlRadius.fillColor = .clear
        controlRadius.lineWidth = Constants.UI.borderWidth
        controlRadius.zPosition = 5
        controlRadius.name = "controlRadius"
        ballContainer.addChild(controlRadius)

        // Main ball
        let ball = SKShapeNode(circleOfRadius: ballRadius)
        ball.fillColor = Constants.Colors.Ball.whiteColor
        ball.strokeColor = Constants.Colors.Ball.strokeColor
        ball.lineWidth = Constants.UI.borderWidth
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
        let dimpleRadius = Constants.Trail.dotRadius

        for i in 0..<dimpleCount {
            let angle = (CGFloat(i) / CGFloat(dimpleCount)) * 2 * .pi
            let dimpleDistance = radius * 0.7
            let x = cos(angle) * dimpleDistance
            let y = sin(angle) * dimpleDistance

            let dimple = SKShapeNode(circleOfRadius: dimpleRadius)
            dimple.position = CGPoint(x: x, y: y)
            dimple.fillColor = Constants.Colors.Ball.dimpleColor
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

        // Also show tracking indicator
        showTrackingIndicator(ballNode)
        print("🎯 Touch feedback: Ball control ring activated with tracking")
    }

    private func showTrackingIndicator(_ ballNode: SKNode) {
        // Remove existing tracking indicator
        ballNode.childNode(withName: "trackingIndicator")?.removeFromParent()

        // Create tracking pulse effect
        let trackingIndicator = SKShapeNode(circleOfRadius: 15)
        trackingIndicator.strokeColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 1.0)
        trackingIndicator.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.2)
        trackingIndicator.lineWidth = 2
        trackingIndicator.zPosition = 9
        trackingIndicator.name = "trackingIndicator"

        // Add pulsing animation
        let scaleUp = SKAction.scale(to: 1.3, duration: 0.5)
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
        let fadeOut = SKAction.fadeAlpha(to: 0.3, duration: 0.5)
        let fadeIn = SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        let pulse = SKAction.sequence([
            SKAction.group([scaleUp, fadeOut]),
            SKAction.group([scaleDown, fadeIn])
        ])
        trackingIndicator.run(SKAction.repeatForever(pulse))

        ballNode.addChild(trackingIndicator)
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
        let arrowPath = createArrowPath(at: relative.cgPoint, direction: relative)
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
        ballNode.childNode(withName: "trackingIndicator")?.removeFromParent()
        print("🚫 Touch feedback: Ball control indicators hidden")
    }

    // MARK: - Ball Trail System
    func createBallTrail(from positions: [Position], in scene: SKScene) {
        // Clear existing trail
        clearBallTrail(from: scene)

        guard positions.count > 1 else { return }

        // Create trail path
        let path = CGMutablePath()
        path.move(to: positions[0].cgPoint)

        for i in 1..<positions.count {
            path.addLine(to: positions[i].cgPoint)
        }

        let trail = SKShapeNode(path: path)
        trail.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.6)
        trail.lineWidth = Constants.Trail.lineWidth
        trail.zPosition = 4
        trail.name = "ballTrail"

        // Add fade animation
        let fadeAction = SKAction.fadeAlpha(to: 0.0, duration: Constants.Animation.trailFadeDuration)
        let removeAction = SKAction.removeFromParent()
        trail.run(SKAction.sequence([fadeAction, removeAction]))

        scene.addChild(trail)

        // Add trail dots for emphasis
        for (index, position) in positions.enumerated() where index % Constants.Trail.dotSpacing == 0 {
            let dot = SKShapeNode(circleOfRadius: Constants.Trail.dotRadius)
            dot.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.0, alpha: 0.8)
            dot.strokeColor = .clear
            dot.position = position.cgPoint
            dot.zPosition = 4
            dot.name = "trailDot"

            let fadeAction = SKAction.fadeAlpha(to: 0.0, duration: Constants.Animation.trailFadeDuration)
            let removeAction = SKAction.removeFromParent()
            dot.run(SKAction.sequence([fadeAction, removeAction]))

            scene.addChild(dot)
        }
    }

    func clearBallTrail(from scene: SKScene) {
        scene.children.filter { $0.name == "ballTrail" || $0.name == "trailDot" }.forEach { $0.removeFromParent() }
    }

    private func createArrowPath(at position: CGPoint, direction: Position) -> CGPath {
        let path = CGMutablePath()
        let arrowSize: CGFloat = 12

        // Calculate the angle of the direction vector
        let angle = atan2(direction.y, direction.x)

        // Create arrow pointing in the direction of the drag
        // Arrow tip at the end position
        let tip = position

        // Calculate the two back points of the arrow
        let backDistance: CGFloat = arrowSize
        let wingSpread: CGFloat = arrowSize * 0.6

        let backAngle1 = angle + .pi - 0.4  // Left wing
        let backAngle2 = angle + .pi + 0.4  // Right wing

        let leftWing = CGPoint(
            x: tip.x + cos(backAngle1) * backDistance,
            y: tip.y + sin(backAngle1) * backDistance
        )

        let rightWing = CGPoint(
            x: tip.x + cos(backAngle2) * backDistance,
            y: tip.y + sin(backAngle2) * backDistance
        )

        // Create the arrow triangle
        path.move(to: tip)
        path.addLine(to: leftWing)
        path.addLine(to: rightWing)
        path.closeSubpath()

        return path
    }
}