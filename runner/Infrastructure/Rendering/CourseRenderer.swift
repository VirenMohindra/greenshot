//
//  CourseRenderer.swift
//  runner
//
//  SpriteKit renderer for golf course graphics and terrain
//

import SpriteKit
import UIKit

protocol CourseRendererProtocol {
    func renderCourse(hole: Hole, in scene: SKScene)
    func renderObstacles(_ obstacles: [Obstacle], in scene: SKScene)
    func clearCourse(in scene: SKScene)
}

class CourseRenderer: CourseRendererProtocol {
    private let courseWorldSize: CGSize

    init(courseWorldSize: CGSize) {
        self.courseWorldSize = courseWorldSize
    }

    func renderCourse(hole: Hole, in scene: SKScene) {
        // Clear existing course
        clearCourse(in: scene)

        // Set background color
        scene.backgroundColor = SKColor(red: 0.13, green: 0.37, blue: 0.15, alpha: 1.0) // Deep rough

        // Create container for course elements
        let courseContainer = SKNode()
        courseContainer.name = "courseContainer"
        courseContainer.zPosition = -5
        scene.addChild(courseContainer)

        // Render course layers
        createRoughArea(in: courseContainer)
        createFairway(hole: hole, in: courseContainer)
        createGreenArea(at: hole.pinPosition, in: courseContainer)
        createTeeBox(at: hole.teePosition, in: courseContainer)
        createVisualEnhancements(in: courseContainer)
    }

    func clearCourse(in scene: SKScene) {
        scene.childNode(withName: "courseContainer")?.removeFromParent()
    }

    // MARK: - Course Elements
    private func createRoughArea(in container: SKNode) {
        // Main rough background
        let roughRect = SKShapeNode(rect: CGRect(origin: .zero, size: courseWorldSize))
        roughRect.fillColor = SKColor(red: 0.16, green: 0.42, blue: 0.18, alpha: 1.0)
        roughRect.strokeColor = .clear
        roughRect.zPosition = 0
        container.addChild(roughRect)

        // Add varied rough patches
        for _ in 0..<15 {
            let patchSize = CGSize(
                width: 80 + drand48() * 120,
                height: 60 + drand48() * 80
            )
            let patch = SKShapeNode(ellipseOf: patchSize)
            patch.position = CGPoint(
                x: drand48() * courseWorldSize.width,
                y: drand48() * courseWorldSize.height
            )
            patch.fillColor = SKColor(red: 0.18, green: 0.45, blue: 0.20, alpha: 0.7)
            patch.strokeColor = .clear
            patch.zPosition = 1
            container.addChild(patch)
        }
    }

    private func createFairway(hole: Hole, in container: SKNode) {
        // Main fairway
        let fairway = SKShapeNode(path: hole.fairwayPath)
        fairway.fillColor = SKColor(red: 0.25, green: 0.55, blue: 0.28, alpha: 1.0)
        fairway.strokeColor = SKColor(red: 0.20, green: 0.48, blue: 0.23, alpha: 1.0)
        fairway.lineWidth = 2
        fairway.zPosition = 2
        fairway.name = "fairway"
        container.addChild(fairway)

        // Add fairway texture
        addFairwayTexture(to: fairway, path: hole.fairwayPath)
    }

    private func createGreenArea(at position: Position, in container: SKNode) {
        let greenRadius: CGFloat = 45
        let green = SKShapeNode(circleOfRadius: greenRadius)
        green.position = position.cgPoint
        green.fillColor = SKColor(red: 0.20, green: 0.50, blue: 0.25, alpha: 1.0)
        green.strokeColor = SKColor(red: 0.15, green: 0.40, blue: 0.20, alpha: 1.0)
        green.lineWidth = 2
        green.zPosition = 3
        green.name = "green"
        container.addChild(green)

        // Add green texture rings
        for i in 0..<3 {
            let textureRadius = greenRadius - CGFloat(i * 8)
            let textureRing = SKShapeNode(circleOfRadius: textureRadius)
            textureRing.position = position.cgPoint
            textureRing.fillColor = .clear
            textureRing.strokeColor = SKColor(red: 0.18, green: 0.45, blue: 0.22, alpha: 0.3)
            textureRing.lineWidth = 1
            textureRing.zPosition = 4
            container.addChild(textureRing)
        }
    }

    private func createTeeBox(at position: Position, in container: SKNode) {
        let teeBox = SKShapeNode(rectOf: CGSize(width: 30, height: 20), cornerRadius: 4)
        teeBox.position = position.cgPoint
        teeBox.fillColor = SKColor(red: 0.22, green: 0.48, blue: 0.25, alpha: 1.0)
        teeBox.strokeColor = SKColor(red: 0.18, green: 0.40, blue: 0.20, alpha: 1.0)
        teeBox.lineWidth = 1
        teeBox.zPosition = 3
        teeBox.name = "teeBox"
        container.addChild(teeBox)
    }

    private func addFairwayTexture(to fairway: SKShapeNode, path: CGPath) {
        let pathBounds = path.boundingBox
        let lineSpacing: CGFloat = 8

        for i in stride(from: pathBounds.minX, to: pathBounds.maxX, by: lineSpacing) {
            let line = SKShapeNode()
            let linePath = CGMutablePath()
            linePath.move(to: CGPoint(x: i, y: pathBounds.minY))
            linePath.addLine(to: CGPoint(x: i, y: pathBounds.maxY))
            line.path = linePath
            line.strokeColor = SKColor(red: 0.22, green: 0.50, blue: 0.26, alpha: 0.3)
            line.lineWidth = 1
            line.zPosition = 1
            fairway.addChild(line)
        }
    }

    private func createVisualEnhancements(in container: SKNode) {
        // Cart path
        let pathWidth: CGFloat = 8
        let cartPath = SKShapeNode(rect: CGRect(x: 30, y: 0, width: pathWidth, height: courseWorldSize.height))
        cartPath.fillColor = SKColor(red: 0.85, green: 0.82, blue: 0.75, alpha: 1.0)
        cartPath.strokeColor = SKColor(red: 0.75, green: 0.70, blue: 0.60, alpha: 1.0)
        cartPath.lineWidth = 1
        cartPath.zPosition = 1
        cartPath.name = "cartPath"
        container.addChild(cartPath)

        // Decorative landscaping
        for _ in 0..<5 {
            let bedSize = CGSize(
                width: 15 + drand48() * 10,
                height: 10 + drand48() * 8
            )
            let flowerBed = SKShapeNode(ellipseOf: bedSize)
            flowerBed.position = CGPoint(
                x: 50 + drand48() * (courseWorldSize.width - 100),
                y: 50 + drand48() * (courseWorldSize.height - 100)
            )
            flowerBed.fillColor = SKColor(red: 0.32, green: 0.25, blue: 0.20, alpha: 1.0)
            flowerBed.strokeColor = .clear
            flowerBed.zPosition = 1
            flowerBed.name = "landscaping"
            container.addChild(flowerBed)
        }
    }
}

// MARK: - Obstacle Rendering
extension CourseRenderer {
    func renderObstacles(_ obstacles: [Obstacle], in scene: SKScene) {
        // Remove existing obstacles
        scene.children.filter { $0.name?.starts(with: "obstacle_") == true }.forEach { $0.removeFromParent() }

        for obstacle in obstacles {
            let obstacleNode = createObstacleNode(obstacle)
            obstacleNode.name = "obstacle_\(obstacle.id.uuidString)"
            scene.addChild(obstacleNode)
        }
    }

    private func createObstacleNode(_ obstacle: Obstacle) -> SKNode {
        switch obstacle.type {
        case .water:
            return createWaterHazard(obstacle: obstacle)
        case .bunker:
            return createSandBunker(obstacle: obstacle)
        case .tree:
            return createTree(obstacle: obstacle)
        case .rough:
            return createRoughPatch(obstacle: obstacle)
        }
    }

    private func createWaterHazard(obstacle: Obstacle) -> SKNode {
        let container = SKNode()
        container.position = obstacle.position.cgPoint
        container.zPosition = 1

        let waterBody = SKShapeNode(rectOf: obstacle.size, cornerRadius: obstacle.size.width * 0.3)
        waterBody.fillColor = SKColor(red: 0.1, green: 0.4, blue: 0.7, alpha: 0.9)
        waterBody.strokeColor = SKColor(red: 0.05, green: 0.3, blue: 0.6, alpha: 1.0)
        waterBody.lineWidth = 2
        container.addChild(waterBody)

        // Add water effects
        for i in 0..<3 {
            let waveSize = CGSize(width: obstacle.size.width * 0.8, height: obstacle.size.height * 0.6)
            let wave = SKShapeNode(ellipseOf: waveSize)
            wave.fillColor = .clear
            wave.strokeColor = SKColor(red: 0.2, green: 0.5, blue: 0.8, alpha: 0.4)
            wave.lineWidth = 1
            wave.position = CGPoint(x: CGFloat(i - 1) * 5, y: CGFloat(i - 1) * 3)
            container.addChild(wave)
        }

        return container
    }

    private func createSandBunker(obstacle: Obstacle) -> SKNode {
        let container = SKNode()
        container.position = obstacle.position.cgPoint
        container.zPosition = 1

        let bunker = SKShapeNode(ellipseOf: obstacle.size)
        bunker.fillColor = SKColor(red: 0.85, green: 0.75, blue: 0.55, alpha: 1.0)
        bunker.strokeColor = SKColor(red: 0.7, green: 0.6, blue: 0.4, alpha: 1.0)
        bunker.lineWidth = 1
        container.addChild(bunker)

        // Add rake marks
        let rakeMarkCount = 4
        for i in 0..<rakeMarkCount {
            let line = SKShapeNode()
            let linePath = CGMutablePath()
            let startX = -obstacle.size.width * 0.4 + (CGFloat(i) / CGFloat(rakeMarkCount - 1)) * obstacle.size.width * 0.8
            linePath.move(to: CGPoint(x: startX, y: -obstacle.size.height * 0.3))
            linePath.addLine(to: CGPoint(x: startX + 5, y: obstacle.size.height * 0.3))
            line.path = linePath
            line.strokeColor = SKColor(red: 0.75, green: 0.65, blue: 0.45, alpha: 0.6)
            line.lineWidth = 1
            container.addChild(line)
        }

        return container
    }

    private func createTree(obstacle: Obstacle) -> SKNode {
        let container = SKNode()
        container.position = obstacle.position.cgPoint
        container.zPosition = 1

        let trunkWidth = obstacle.size.width * 0.3
        let trunkHeight = obstacle.size.height * 0.4
        let crownRadius = obstacle.size.width * 0.5

        // Trunk
        let trunk = SKShapeNode(rectOf: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
        trunk.strokeColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
        trunk.lineWidth = 1
        trunk.position = CGPoint(x: 0, y: -trunkHeight * 0.5)
        container.addChild(trunk)

        // Crown
        let crown = SKShapeNode(circleOfRadius: crownRadius)
        crown.fillColor = SKColor(red: 0.15, green: 0.5, blue: 0.2, alpha: 1.0)
        crown.strokeColor = SKColor(red: 0.1, green: 0.4, blue: 0.15, alpha: 1.0)
        crown.lineWidth = 1
        crown.position = CGPoint(x: 0, y: crownRadius - trunkHeight * 0.3)
        container.addChild(crown)

        return container
    }

    private func createRoughPatch(obstacle: Obstacle) -> SKNode {
        let roughPatch = SKShapeNode(rectOf: obstacle.size)
        roughPatch.position = obstacle.position.cgPoint
        roughPatch.fillColor = SKColor(red: 0.4, green: 0.6, blue: 0.3, alpha: 0.7)
        roughPatch.strokeColor = .clear
        roughPatch.zPosition = 1
        return roughPatch
    }
}