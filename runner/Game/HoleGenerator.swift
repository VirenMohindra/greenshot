//
//  HoleGenerator.swift
//  runner
//
//  Procedural golf hole generation system
//

import Foundation
import SpriteKit

class HoleGenerator {

    // MARK: - Properties
    private let sceneSize: CGSize
    private let randomSeed: UInt64

    struct GeneratedHole {
        let teePosition: CGPoint
        let holePosition: CGPoint
        let fairwayPath: CGPath
        let obstacles: [ObstacleData]
        let par: Int
        let distance: Float
    }

    struct ObstacleData {
        let type: ObstacleType
        let position: CGPoint
        let size: CGSize

        enum ObstacleType {
            case water
            case bunker
            case tree
            case rough
        }
    }

    // MARK: - Initialization
    init(sceneSize: CGSize, seed: UInt64 = UInt64(Date().timeIntervalSince1970)) {
        self.sceneSize = sceneSize
        self.randomSeed = seed
        srand48(Int(seed))
    }

    // MARK: - Generation
    func generateHole(number: Int, difficulty: Float) -> GeneratedHole {
        // Set random seed for consistent generation
        srand48(Int(randomSeed + UInt64(number)))

        // Calculate base positions - tee always at bottom center with slight variation
        let teePosition = CGPoint(
            x: sceneSize.width * 0.5 + (drand48() - 0.5) * sceneSize.width * 0.1,
            y: sceneSize.height * 0.1 + drand48() * sceneSize.height * 0.05
        )
        let holePosition = generateHolePosition(difficulty: difficulty)

        // Calculate distance and par
        let distance = Float(hypot(holePosition.x - teePosition.x, holePosition.y - teePosition.y))
        let par = calculatePar(distance: distance, difficulty: difficulty)

        // Generate fairway path
        let fairwayPath = generateFairwayPath(from: teePosition, to: holePosition, difficulty: difficulty)

        // Generate obstacles
        let obstacles = generateObstacles(
            fairwayPath: fairwayPath,
            teePosition: teePosition,
            holePosition: holePosition,
            difficulty: difficulty
        )

        return GeneratedHole(
            teePosition: teePosition,
            holePosition: holePosition,
            fairwayPath: fairwayPath,
            obstacles: obstacles,
            par: par,
            distance: distance
        )
    }

    // MARK: - Private Generation Methods
    private func generateHolePosition(difficulty: Float) -> CGPoint {
        // Position holes further up the course with more variation
        var baseY = sceneSize.height * (0.7 + 0.2 * CGFloat(difficulty)) // 70% to 90% up the course
        var baseX = sceneSize.width * 0.5

        // Add variation based on difficulty
        let maxXVariation = sceneSize.width * 0.35 * CGFloat(difficulty)
        let maxYVariation = sceneSize.height * 0.1 * CGFloat(difficulty)

        baseX += (drand48() - 0.5) * maxXVariation
        baseY += (drand48() - 0.5) * maxYVariation

        // Keep within bounds with some margin
        baseX = max(sceneSize.width * 0.15, min(sceneSize.width * 0.85, baseX))
        baseY = max(sceneSize.height * 0.6, min(sceneSize.height * 0.95, baseY))

        return CGPoint(x: baseX, y: baseY)
    }

    private func calculatePar(distance: Float, difficulty: Float) -> Int {
        let adjustedDistance = distance * (1.0 + difficulty * 0.3)

        switch adjustedDistance {
        case 0..<200: return 3
        case 200..<350: return 4
        case 350...: return 5
        default: return 4
        }
    }

    private func generateFairwayPath(from start: CGPoint, to end: CGPoint, difficulty: Float) -> CGPath {
        let path = CGMutablePath()
        let fairwayWidth: CGFloat = 100 - (CGFloat(difficulty) * 30) // Narrower fairways with difficulty

        // Create a path with curves based on difficulty
        let controlPointCount = Int(2 + difficulty * 3) // More control points = more curves
        var pathPoints: [CGPoint] = [start]

        // Generate intermediate control points
        for i in 1..<controlPointCount {
            let progress = CGFloat(i) / CGFloat(controlPointCount)
            let baseX = start.x + (end.x - start.x) * progress
            let baseY = start.y + (end.y - start.y) * progress

            // Add curve variation
            let maxVariation = 50 + (Double(difficulty) * 80)
            let xVariation = (drand48() - 0.5) * maxVariation
            let yVariation = (drand48() - 0.5) * maxVariation * 0.5

            pathPoints.append(CGPoint(x: baseX + xVariation, y: baseY + yVariation))
        }

        pathPoints.append(end)

        // Create smooth fairway outline
        path.move(to: offsetPoint(pathPoints[0], distance: fairwayWidth/2, perpendicular: true))

        // Add points along one side
        for i in 0..<pathPoints.count-1 {
            let current = pathPoints[i]
            let next = pathPoints[i+1]
            let direction = CGPoint(x: next.x - current.x, y: next.y - current.y)
            let perpendicular = CGPoint(x: -direction.y, y: direction.x)
            let magnitude = sqrt(perpendicular.x * perpendicular.x + perpendicular.y * perpendicular.y)

            if magnitude > 0 {
                let normalized = CGPoint(x: perpendicular.x / magnitude, y: perpendicular.y / magnitude)
                let offset = CGPoint(
                    x: current.x + normalized.x * fairwayWidth/2,
                    y: current.y + normalized.y * fairwayWidth/2
                )
                path.addLine(to: offset)
            }
        }

        // Add end point
        if let lastPoint = pathPoints.last {
            path.addLine(to: offsetPoint(lastPoint, distance: fairwayWidth/2, perpendicular: true))
        }

        // Add points along other side (in reverse)
        for i in (0..<pathPoints.count-1).reversed() {
            let current = pathPoints[i+1]
            let previous = pathPoints[i]
            let direction = CGPoint(x: previous.x - current.x, y: previous.y - current.y)
            let perpendicular = CGPoint(x: -direction.y, y: direction.x)
            let magnitude = sqrt(perpendicular.x * perpendicular.x + perpendicular.y * perpendicular.y)

            if magnitude > 0 {
                let normalized = CGPoint(x: perpendicular.x / magnitude, y: perpendicular.y / magnitude)
                let offset = CGPoint(
                    x: current.x + normalized.x * fairwayWidth/2,
                    y: current.y + normalized.y * fairwayWidth/2
                )
                path.addLine(to: offset)
            }
        }

        path.closeSubpath()

        return path
    }

    private func offsetPoint(_ point: CGPoint, distance: CGFloat, perpendicular: Bool) -> CGPoint {
        // Simple offset for start/end points
        return CGPoint(x: point.x + distance, y: point.y)
    }

    private func generateObstacles(
        fairwayPath: CGPath,
        teePosition: CGPoint,
        holePosition: CGPoint,
        difficulty: Float
    ) -> [ObstacleData] {
        var obstacles: [ObstacleData] = []

        // Calculate number of obstacles based on difficulty
        let waterCount = Int(difficulty * 2)
        let bunkerCount = Int(2 + difficulty * 4)
        let treeCount = Int(1 + difficulty * 3)

        // Generate water hazards
        for _ in 0..<waterCount {
            let position = generateObstaclePosition(
                avoiding: fairwayPath,
                teePosition: teePosition,
                holePosition: holePosition,
                preferredDistance: 0.6
            )

            obstacles.append(ObstacleData(
                type: .water,
                position: position,
                size: CGSize(width: 60 + drand48() * 40, height: 40 + drand48() * 20)
            ))
        }

        // Generate bunkers
        for _ in 0..<bunkerCount {
            let position = generateObstaclePosition(
                avoiding: fairwayPath,
                teePosition: teePosition,
                holePosition: holePosition,
                preferredDistance: 0.3
            )

            obstacles.append(ObstacleData(
                type: .bunker,
                position: position,
                size: CGSize(width: 30 + drand48() * 20, height: 20 + drand48() * 15)
            ))
        }

        // Generate trees
        for _ in 0..<treeCount {
            let position = generateObstaclePosition(
                avoiding: fairwayPath,
                teePosition: teePosition,
                holePosition: holePosition,
                preferredDistance: 0.4
            )

            obstacles.append(ObstacleData(
                type: .tree,
                position: position,
                size: CGSize(width: 15 + drand48() * 10, height: 15 + drand48() * 10)
            ))
        }

        return obstacles
    }

    private func generateObstaclePosition(
        avoiding fairwayPath: CGPath,
        teePosition: CGPoint,
        holePosition: CGPoint,
        preferredDistance: Float
    ) -> CGPoint {
        var attempts = 0
        let maxAttempts = 20

        while attempts < maxAttempts {
            // Generate random position
            let x = drand48() * sceneSize.width
            let y = teePosition.y + drand48() * (holePosition.y - teePosition.y)
            let position = CGPoint(x: x, y: y)

            // Check if position is valid (not too close to fairway)
            if !fairwayPath.contains(position) &&
               !isNearImportantArea(position, teePosition: teePosition, holePosition: holePosition) {
                return position
            }

            attempts += 1
        }

        // Fallback position
        return CGPoint(
            x: sceneSize.width * 0.2 + drand48() * sceneSize.width * 0.6,
            y: teePosition.y + 0.3 * (holePosition.y - teePosition.y)
        )
    }

    private func isNearImportantArea(_ position: CGPoint, teePosition: CGPoint, holePosition: CGPoint) -> Bool {
        let teeDistance = hypot(position.x - teePosition.x, position.y - teePosition.y)
        let holeDistance = hypot(position.x - holePosition.x, position.y - holePosition.y)

        return teeDistance < 80 || holeDistance < 60
    }
}