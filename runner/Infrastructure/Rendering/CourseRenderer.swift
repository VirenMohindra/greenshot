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
                width: 80 + Double.random(in: 0...1) * 120,
                height: 60 + Double.random(in: 0...1) * 80
            )
            let patch = SKShapeNode(ellipseOf: patchSize)
            patch.position = CGPoint(
                x: Double.random(in: 0...1) * courseWorldSize.width,
                y: Double.random(in: 0...1) * courseWorldSize.height
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
        let sampleSpacing: CGFloat = 4 // How often to sample along the line

        for x in stride(from: pathBounds.minX, to: pathBounds.maxX, by: lineSpacing) {
            var lineSegments: [(start: CGPoint, end: CGPoint)] = []
            var currentSegmentStart: CGPoint?

            // Sample points along the vertical line to find segments within the fairway
            for y in stride(from: pathBounds.minY, to: pathBounds.maxY, by: sampleSpacing) {
                let point = CGPoint(x: x, y: y)
                let isInside = path.contains(point)

                if isInside {
                    // Point is inside fairway
                    if currentSegmentStart == nil {
                        // Start a new segment
                        currentSegmentStart = point
                    }
                } else {
                    // Point is outside fairway
                    if let segmentStart = currentSegmentStart {
                        // End the current segment
                        let segmentEnd = CGPoint(x: x, y: y - sampleSpacing)
                        lineSegments.append((start: segmentStart, end: segmentEnd))
                        currentSegmentStart = nil
                    }
                }
            }

            // Close any remaining segment
            if let segmentStart = currentSegmentStart {
                let segmentEnd = CGPoint(x: x, y: pathBounds.maxY)
                lineSegments.append((start: segmentStart, end: segmentEnd))
            }

            // Create line nodes for each segment that's actually in the fairway
            for segment in lineSegments {
                // Only draw segments that are long enough to be visible
                let segmentLength = abs(segment.end.y - segment.start.y)
                if segmentLength > sampleSpacing * 2 {
                    let line = SKShapeNode()
                    let linePath = CGMutablePath()
                    linePath.move(to: segment.start)
                    linePath.addLine(to: segment.end)
                    line.path = linePath
                    line.strokeColor = SKColor(red: 0.22, green: 0.50, blue: 0.26, alpha: 0.3)
                    line.lineWidth = 1
                    line.zPosition = 1
                    fairway.addChild(line)
                }
            }
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
                width: 15 + Double.random(in: 0...1) * 10,
                height: 10 + Double.random(in: 0...1) * 8
            )
            let flowerBed = SKShapeNode(ellipseOf: bedSize)
            flowerBed.position = CGPoint(
                x: 50 + Double.random(in: 0...1) * (courseWorldSize.width - 100),
                y: 50 + Double.random(in: 0...1) * (courseWorldSize.height - 100)
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

        // Add rake marks - clipped to bunker boundaries
        addBunkerTexture(to: bunker, size: obstacle.size)

        return container
    }

    private func addBunkerTexture(to bunker: SKShapeNode, size: CGSize) {
        // Get the ellipse path for boundary testing
        let ellipsePath = CGPath(ellipseIn: CGRect(x: -size.width/2, y: -size.height/2, width: size.width, height: size.height), transform: nil)

        let lineSpacing: CGFloat = 8
        let lineLength: CGFloat = min(size.width, size.height) * 0.6
        let rakeMarkCount = 4

        for i in 0..<rakeMarkCount {
            let startX = -size.width * 0.4 + (CGFloat(i) / CGFloat(rakeMarkCount - 1)) * size.width * 0.8

            // Sample points along the line and only draw segments within the ellipse
            let sampleCount = 20
            var lineSegments: [CGPoint] = []

            for j in 0..<sampleCount {
                let progress = CGFloat(j) / CGFloat(sampleCount - 1)
                let y = -size.height * 0.3 + progress * size.height * 0.6
                let x = startX + progress * 5 // Slight angle like original
                let point = CGPoint(x: x, y: y)

                if ellipsePath.contains(point) {
                    lineSegments.append(point)
                }
            }

            // Create line segments only for points inside the ellipse
            if lineSegments.count > 1 {
                let line = SKShapeNode()
                let linePath = CGMutablePath()

                if let firstPoint = lineSegments.first {
                    linePath.move(to: firstPoint)
                    for point in lineSegments.dropFirst() {
                        linePath.addLine(to: point)
                    }
                }

                line.path = linePath
                line.strokeColor = SKColor(red: 0.75, green: 0.65, blue: 0.45, alpha: 0.6)
                line.lineWidth = 1
                bunker.addChild(line)
            }
        }
    }

    private func createTree(obstacle: Obstacle) -> SKNode {
        let container = SKNode()
        container.position = obstacle.position.cgPoint
        container.zPosition = 1

        // Determine tree type based on size and random factor
        let treeType = determineTreeType(size: obstacle.size)

        // Apply size variation
        let sizeVariation = 1.0 + (Double.random(in: -1...1) * Constants.Course.Obstacles.treeHeightVariation)
        let adjustedSize = CGSize(
            width: obstacle.size.width * sizeVariation,
            height: obstacle.size.height * sizeVariation
        )

        switch treeType {
        case .oak:
            return createOakTree(size: adjustedSize, container: container)
        case .pine:
            return createPineTree(size: adjustedSize, container: container)
        case .palm:
            return createPalmTree(size: adjustedSize, container: container)
        }
    }

    private enum TreeType {
        case oak, pine, palm
    }

    private func determineTreeType(size: CGSize) -> TreeType {
        let random = Double.random(in: 0...1)
        if size.width > 35 {
            // Larger trees are more likely to be oaks
            return random < 0.6 ? .oak : (random < 0.8 ? .pine : .palm)
        } else {
            // Smaller trees favor pines
            return random < 0.5 ? .pine : (random < 0.8 ? .oak : .palm)
        }
    }

    private func createOakTree(size: CGSize, container: SKNode) -> SKNode {
        let trunkWidth = size.width * 0.25
        let trunkHeight = size.height * 0.45
        let crownRadius = size.width * 0.55

        // Trunk with slight taper
        let trunkPath = CGMutablePath()
        let topWidth = trunkWidth * 0.8
        trunkPath.move(to: CGPoint(x: -trunkWidth/2, y: -trunkHeight))
        trunkPath.addLine(to: CGPoint(x: trunkWidth/2, y: -trunkHeight))
        trunkPath.addLine(to: CGPoint(x: topWidth/2, y: 0))
        trunkPath.addLine(to: CGPoint(x: -topWidth/2, y: 0))
        trunkPath.closeSubpath()

        let trunk = SKShapeNode(path: trunkPath)
        trunk.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.12, alpha: 1.0)
        trunk.strokeColor = SKColor(red: 0.25, green: 0.15, blue: 0.08, alpha: 1.0)
        trunk.lineWidth = 1
        container.addChild(trunk)

        // Multiple crown layers for depth
        for i in 0..<3 {
            let layerRadius = crownRadius * (1.0 - CGFloat(i) * 0.15)
            let yOffset = CGFloat(i) * crownRadius * 0.2

            let crown = SKShapeNode(circleOfRadius: layerRadius)
            crown.fillColor = SKColor(
                red: 0.12 + CGFloat(i) * 0.03,
                green: 0.45 + CGFloat(i) * 0.05,
                blue: 0.18 + CGFloat(i) * 0.02,
                alpha: 0.9 - CGFloat(i) * 0.1
            )
            crown.strokeColor = .clear
            crown.position = CGPoint(x: CGFloat(i - 1) * 2, y: crownRadius * 0.6 + yOffset)
            crown.zPosition = -CGFloat(i)
            container.addChild(crown)
        }

        return container
    }

    private func createPineTree(size: CGSize, container: SKNode) -> SKNode {
        let trunkWidth = size.width * 0.2
        let trunkHeight = size.height * 0.3
        let crownHeight = size.height * 0.75

        // Trunk
        let trunk = SKShapeNode(rectOf: CGSize(width: trunkWidth, height: trunkHeight))
        trunk.fillColor = SKColor(red: 0.4, green: 0.25, blue: 0.15, alpha: 1.0)
        trunk.strokeColor = SKColor(red: 0.3, green: 0.18, blue: 0.1, alpha: 1.0)
        trunk.lineWidth = 1
        trunk.position = CGPoint(x: 0, y: -trunkHeight * 0.5)
        container.addChild(trunk)

        // Triangular pine crown with multiple layers
        for i in 0..<4 {
            let layerWidth = size.width * (0.8 - CGFloat(i) * 0.15)
            let layerHeight = crownHeight * 0.35
            let yPos = crownHeight * 0.4 - CGFloat(i) * layerHeight * 0.6

            let trianglePath = CGMutablePath()
            trianglePath.move(to: CGPoint(x: 0, y: yPos + layerHeight * 0.5))
            trianglePath.addLine(to: CGPoint(x: -layerWidth * 0.5, y: yPos - layerHeight * 0.5))
            trianglePath.addLine(to: CGPoint(x: layerWidth * 0.5, y: yPos - layerHeight * 0.5))
            trianglePath.closeSubpath()

            let layer = SKShapeNode(path: trianglePath)
            layer.fillColor = SKColor(
                red: 0.08,
                green: 0.35 + CGFloat(i) * 0.03,
                blue: 0.12,
                alpha: 1.0
            )
            layer.strokeColor = SKColor(red: 0.06, green: 0.25, blue: 0.08, alpha: 1.0)
            layer.lineWidth = 1
            layer.zPosition = -CGFloat(i)
            container.addChild(layer)
        }

        return container
    }

    private func createPalmTree(size: CGSize, container: SKNode) -> SKNode {
        let trunkWidth = size.width * 0.15
        let trunkHeight = size.height * 0.7

        // Curved trunk with segments
        for i in 0..<5 {
            let segmentHeight = trunkHeight / 5
            let segmentY = -trunkHeight + CGFloat(i) * segmentHeight + segmentHeight * 0.5
            let curve = sin(CGFloat(i) * 0.3) * size.width * 0.1

            let segment = SKShapeNode(rectOf: CGSize(width: trunkWidth, height: segmentHeight))
            segment.fillColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
            segment.strokeColor = SKColor(red: 0.5, green: 0.3, blue: 0.15, alpha: 1.0)
            segment.lineWidth = 1
            segment.position = CGPoint(x: curve, y: segmentY)
            container.addChild(segment)
        }

        // Palm fronds
        let frondCount = 8
        for i in 0..<frondCount {
            let angle = (CGFloat(i) / CGFloat(frondCount)) * 2 * .pi
            let frondLength = size.width * 0.6
            let frondWidth = size.width * 0.1

            let frondPath = CGMutablePath()
            frondPath.move(to: CGPoint(x: 0, y: 0))
            frondPath.addQuadCurve(
                to: CGPoint(x: frondLength * cos(angle), y: frondLength * sin(angle)),
                control: CGPoint(x: frondLength * 0.5 * cos(angle), y: frondLength * 0.7 * sin(angle))
            )

            let frond = SKShapeNode(path: frondPath)
            frond.strokeColor = SKColor(red: 0.2, green: 0.6, blue: 0.25, alpha: 1.0)
            frond.lineWidth = frondWidth
            frond.position = CGPoint(x: 0, y: trunkHeight * 0.3)
            container.addChild(frond)
        }

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