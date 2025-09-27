//
//  HoleGenerationService.swift
//  runner
//
//  Domain service for procedural golf hole generation
//

import Foundation
import CoreGraphics

protocol HoleGenerationServiceProtocol {
    func generateHole(number: Int, difficulty: Difficulty, worldSize: CGSize) -> Hole
    func generateCourse(holeCount: Int, name: String, worldSize: CGSize) -> Course
}

class HoleGenerationService: HoleGenerationServiceProtocol {
    private let scoringService: ScoringServiceProtocol
    private let randomSeed: UInt64

    init(scoringService: ScoringServiceProtocol, seed: UInt64? = nil) {
        self.scoringService = scoringService
        self.randomSeed = seed ?? UInt64(Date().timeIntervalSince1970)
    }

    // MARK: - Hole Generation
    func generateHole(number: Int, difficulty: Difficulty, worldSize: CGSize) -> Hole {
        // Set deterministic random seed for consistent generation
        srand48(Int(randomSeed + UInt64(number)))

        let teePosition = generateTeePosition(worldSize: worldSize)
        let pinPosition = generatePinPosition(difficulty: difficulty, worldSize: worldSize)
        let distance = teePosition.distance(to: pinPosition)
        let par = scoringService.calculateParForDistance(distance, difficulty: difficulty)
        let fairwayPath = generateFairwayPath(from: teePosition, to: pinPosition, difficulty: difficulty)
        let obstacles = generateObstacles(
            fairwayPath: fairwayPath,
            teePosition: teePosition,
            pinPosition: pinPosition,
            difficulty: difficulty,
            worldSize: worldSize
        )

        return Hole(
            number: number,
            par: par,
            difficulty: difficulty,
            teePosition: teePosition,
            pinPosition: pinPosition,
            fairwayPath: fairwayPath,
            obstacles: obstacles
        )
    }

    // MARK: - Course Generation
    func generateCourse(holeCount: Int = 18, name: String, worldSize: CGSize) -> Course {
        var holes: [Hole] = []

        for holeNumber in 1...holeCount {
            let difficulty = calculateDynamicDifficulty(holeNumber: holeNumber, totalHoles: holeCount)
            let hole = generateHole(number: holeNumber, difficulty: difficulty, worldSize: worldSize)
            holes.append(hole)
        }

        return Course(name: name, holes: holes, worldSize: worldSize)
    }

    private func calculateDynamicDifficulty(holeNumber: Int, totalHoles: Int) -> Difficulty {
        // Progressive difficulty that makes sense for golf
        let progress = Double(holeNumber - 1) / Double(totalHoles - 1)

        // Create signature holes and vary difficulty
        let difficultyLevel: Double
        switch holeNumber {
        case 1, 10: // Opening holes - easier
            difficultyLevel = 0.2
        case 9, 18: // Closing holes - harder
            difficultyLevel = 0.8
        case let n where n % 3 == 0: // Every 3rd hole is harder
            difficultyLevel = min(0.9, 0.4 + progress * 0.5)
        default:
            difficultyLevel = 0.3 + progress * 0.4 // Gradual progression
        }

        return Difficulty(level: difficultyLevel)
    }

    // MARK: - Private Generation Methods
    private func generateTeePosition(worldSize: CGSize) -> Position {
        // Tee always at bottom center with slight variation
        Position(
            x: worldSize.width * 0.5 + (drand48() - 0.5) * worldSize.width * 0.1,
            y: worldSize.height * 0.1 + drand48() * worldSize.height * 0.05
        )
    }

    private func generatePinPosition(difficulty: Difficulty, worldSize: CGSize) -> Position {
        // Much more realistic golf distances (in yards, converted to points)
        let minDistance: Double = 100 // Short par 3
        let maxDistance: Double = 550 // Long par 5

        // Distance based on par that will be calculated
        let baseDistance: Double
        let randomFactor = drand48()

        if randomFactor < 0.3 { // 30% Par 3 holes
            baseDistance = 100 + drand48() * 150 // 100-250 yards
        } else if randomFactor < 0.8 { // 50% Par 4 holes
            baseDistance = 250 + drand48() * 200 // 250-450 yards
        } else { // 20% Par 5 holes
            baseDistance = 450 + drand48() * 100 // 450-550 yards
        }

        // Add difficulty variation
        let difficultyModifier = 1.0 + Double(difficulty.level) * 0.3
        let targetDistance = baseDistance * difficultyModifier

        // Random angle from tee with much more variation
        let baseAngle = Double.pi / 2 // Straight up
        let maxAngleVariation = Double.pi / 3 // Up to 60 degrees left or right
        let angle = baseAngle + (drand48() - 0.5) * maxAngleVariation

        // Calculate position based on distance and angle from tee center
        let teeCenter = Position(x: worldSize.width * 0.5, y: worldSize.height * 0.1)
        let pinX = teeCenter.x + cos(angle) * targetDistance
        let pinY = teeCenter.y + sin(angle) * targetDistance

        // Keep within course bounds with proper margins
        let constrainedX = max(worldSize.width * 0.15, min(worldSize.width * 0.85, pinX))
        let constrainedY = max(worldSize.height * 0.4, min(worldSize.height * 0.95, pinY))

        return Position(x: constrainedX, y: constrainedY)
    }

    private func generateFairwayPath(from start: Position, to end: Position, difficulty: Difficulty) -> CGPath {
        let path = CGMutablePath()
        let fairwayWidth: CGFloat = 70 - (CGFloat(difficulty.level) * 20) // 70 to 50 width

        // Determine hole type based on distance and random factor
        let distance = start.distance(to: end)
        let holeType = determineHoleType(distance: distance, difficulty: difficulty)

        switch holeType {
        case .straight:
            return createStraightFairway(from: start, to: end, width: fairwayWidth, path: path)

        case .doglegLeft:
            return createDoglegFairway(from: start, to: end, width: fairwayWidth, bendDirection: -.pi/4, path: path)

        case .doglegRight:
            return createDoglegFairway(from: start, to: end, width: fairwayWidth, bendDirection: .pi/4, path: path)

        case .sBend:
            return createSBendFairway(from: start, to: end, width: fairwayWidth, path: path)
        }
    }

    private enum HoleType {
        case straight
        case doglegLeft
        case doglegRight
        case sBend
    }

    private func determineHoleType(distance: CGFloat, difficulty: Difficulty) -> HoleType {
        let random = drand48()

        // Short holes are usually straight
        if distance < 200 {
            return random < 0.8 ? .straight : (random < 0.9 ? .doglegLeft : .doglegRight)
        }

        // Medium holes can be anything
        if distance < 400 {
            switch random {
            case 0.0..<0.4: return .straight
            case 0.4..<0.7: return .doglegLeft
            case 0.7..<0.9: return .doglegRight
            default: return .sBend
            }
        }

        // Long holes favor doglegs and S-bends
        switch random {
        case 0.0..<0.2: return .straight
        case 0.2..<0.5: return .doglegLeft
        case 0.5..<0.8: return .doglegRight
        default: return .sBend
        }
    }

    private func createStraightFairway(from start: Position, to end: Position, width: CGFloat, path: CGMutablePath) -> CGPath {
        let leftEdge = Position(x: start.x - width/2, y: start.y)
        let rightEdge = Position(x: start.x + width/2, y: start.y)
        let leftPin = Position(x: end.x - width/2, y: end.y)
        let rightPin = Position(x: end.x + width/2, y: end.y)

        path.move(to: leftEdge.cgPoint)
        path.addLine(to: leftPin.cgPoint)
        path.addLine(to: rightPin.cgPoint)
        path.addLine(to: rightEdge.cgPoint)
        path.closeSubpath()

        return path
    }

    private func createDoglegFairway(from start: Position, to end: Position, width: CGFloat, bendDirection: Double, path: CGMutablePath) -> CGPath {
        // Create smooth curved fairway for dogleg
        let distance = start.distance(to: end)
        let bendDistance = distance * (0.5 + drand48() * 0.2) // Bend around middle

        // Calculate control points for smooth curve
        let initialDirection = start.direction(to: end)
        let bendIntensity = abs(bendDirection) * 0.8 // Scale the bend

        // Control point for the curve
        let controlPoint = Position(
            x: start.x + cos(Double(initialDirection)) * bendDistance + cos(Double(initialDirection + Double.pi/2)) * bendIntensity * 60,
            y: start.y + sin(Double(initialDirection)) * bendDistance + sin(Double(initialDirection + Double.pi/2)) * bendIntensity * 60
        )

        return createSmoothFairway(from: start, to: end, controlPoint: controlPoint, width: width)
    }

    private func createSBendFairway(from start: Position, to end: Position, width: CGFloat, path: CGMutablePath) -> CGPath {
        let distance = start.distance(to: end)
        let baseDirection = start.direction(to: end)

        // Create two control points for S-curve
        let bend1 = (drand48() - 0.5) * 0.6 * 80 // Bend strength
        let bend2 = -bend1 // Opposite bend

        let control1 = Position(
            x: start.x + cos(Double(baseDirection)) * distance * 0.33 + cos(Double(baseDirection + Double.pi/2)) * bend1,
            y: start.y + sin(Double(baseDirection)) * distance * 0.33 + sin(Double(baseDirection + Double.pi/2)) * bend1
        )

        let control2 = Position(
            x: start.x + cos(Double(baseDirection)) * distance * 0.67 + cos(Double(baseDirection + Double.pi/2)) * bend2,
            y: start.y + sin(Double(baseDirection)) * distance * 0.67 + sin(Double(baseDirection + Double.pi/2)) * bend2
        )

        return createSmoothFairwayWithTwoControls(from: start, to: end, control1: control1, control2: control2, width: width)
    }

    private func createSmoothFairway(from start: Position, to end: Position, controlPoint: Position, width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let steps = 20 // Number of points along the curve

        // Generate points along the quadratic Bezier curve
        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []

        for i in 0...steps {
            let t = Double(i) / Double(steps)

            // Quadratic Bezier formula: P = (1-t)²P₀ + 2(1-t)tP₁ + t²P₂
            let curvePoint = Position(
                x: pow(1-t, 2) * start.x + 2*(1-t)*t * controlPoint.x + pow(t, 2) * end.x,
                y: pow(1-t, 2) * start.y + 2*(1-t)*t * controlPoint.y + pow(t, 2) * end.y
            )

            // Calculate tangent direction at this point
            let tangent = Position(
                x: 2*(1-t) * (controlPoint.x - start.x) + 2*t * (end.x - controlPoint.x),
                y: 2*(1-t) * (controlPoint.y - start.y) + 2*t * (end.y - controlPoint.y)
            ).normalized()

            // Calculate perpendicular for width
            let perpendicular = Position(x: -tangent.y, y: tangent.x)
            let halfWidth = Double(width) / 2

            leftPoints.append(CGPoint(
                x: curvePoint.x + perpendicular.x * halfWidth,
                y: curvePoint.y + perpendicular.y * halfWidth
            ))
            rightPoints.append(CGPoint(
                x: curvePoint.x - perpendicular.x * halfWidth,
                y: curvePoint.y - perpendicular.y * halfWidth
            ))
        }

        // Build the path
        path.move(to: leftPoints[0])
        for i in 1..<leftPoints.count {
            path.addLine(to: leftPoints[i])
        }
        for i in stride(from: rightPoints.count - 1, through: 0, by: -1) {
            path.addLine(to: rightPoints[i])
        }
        path.closeSubpath()

        return path
    }

    private func createSmoothFairwayWithTwoControls(from start: Position, to end: Position, control1: Position, control2: Position, width: CGFloat) -> CGPath {
        let path = CGMutablePath()
        let steps = 30 // More points for smoother S-curve

        var leftPoints: [CGPoint] = []
        var rightPoints: [CGPoint] = []

        for i in 0...steps {
            let t = Double(i) / Double(steps)

            // Cubic Bezier formula: P = (1-t)³P₀ + 3(1-t)²tP₁ + 3(1-t)t²P₂ + t³P₃
            let curvePoint = Position(
                x: pow(1-t, 3) * start.x + 3*pow(1-t, 2)*t * control1.x + 3*(1-t)*pow(t, 2) * control2.x + pow(t, 3) * end.x,
                y: pow(1-t, 3) * start.y + 3*pow(1-t, 2)*t * control1.y + 3*(1-t)*pow(t, 2) * control2.y + pow(t, 3) * end.y
            )

            // Calculate tangent direction
            let tangent = Position(
                x: 3*pow(1-t, 2) * (control1.x - start.x) + 6*(1-t)*t * (control2.x - control1.x) + 3*pow(t, 2) * (end.x - control2.x),
                y: 3*pow(1-t, 2) * (control1.y - start.y) + 6*(1-t)*t * (control2.y - control1.y) + 3*pow(t, 2) * (end.y - control2.y)
            ).normalized()

            let perpendicular = Position(x: -tangent.y, y: tangent.x)
            let halfWidth = Double(width) / 2

            leftPoints.append(CGPoint(
                x: curvePoint.x + perpendicular.x * halfWidth,
                y: curvePoint.y + perpendicular.y * halfWidth
            ))
            rightPoints.append(CGPoint(
                x: curvePoint.x - perpendicular.x * halfWidth,
                y: curvePoint.y - perpendicular.y * halfWidth
            ))
        }

        // Build the path
        path.move(to: leftPoints[0])
        for i in 1..<leftPoints.count {
            path.addLine(to: leftPoints[i])
        }
        for i in stride(from: rightPoints.count - 1, through: 0, by: -1) {
            path.addLine(to: rightPoints[i])
        }
        path.closeSubpath()

        return path
    }

    private func createFairwaySegment(from start: Position, to end: Position, width: CGFloat, path: CGMutablePath) {
        let direction = start.direction(to: end)
        let perpendicular = direction + Double.pi/2

        let startLeft = Position(
            x: start.x + cos(Double(perpendicular)) * Double(width/2),
            y: start.y + sin(Double(perpendicular)) * Double(width/2)
        )
        let startRight = Position(
            x: start.x - cos(Double(perpendicular)) * Double(width/2),
            y: start.y - sin(Double(perpendicular)) * Double(width/2)
        )
        let endLeft = Position(
            x: end.x + cos(Double(perpendicular)) * Double(width/2),
            y: end.y + sin(Double(perpendicular)) * Double(width/2)
        )
        let endRight = Position(
            x: end.x - cos(Double(perpendicular)) * Double(width/2),
            y: end.y - sin(Double(perpendicular)) * Double(width/2)
        )

        if path.isEmpty {
            path.move(to: startLeft.cgPoint)
        }
        path.addLine(to: endLeft.cgPoint)
        path.addLine(to: endRight.cgPoint)
        path.addLine(to: startRight.cgPoint)
        path.closeSubpath()
    }


    private func generateObstacles(
        fairwayPath: CGPath,
        teePosition: Position,
        pinPosition: Position,
        difficulty: Difficulty,
        worldSize: CGSize
    ) -> [Obstacle] {
        var obstacles: [Obstacle] = []

        // Generate water hazards
        let waterCount = difficulty.waterHazardChance > Float(drand48()) ? 1 : 0
        for _ in 0..<waterCount {
            if let position = generateObstaclePosition(
                avoiding: fairwayPath,
                teePosition: teePosition,
                pinPosition: pinPosition,
                worldSize: worldSize
            ) {
                obstacles.append(Obstacle(
                    type: .water,
                    position: position,
                    size: CGSize(width: 60 + drand48() * 40, height: 40 + drand48() * 20)
                ))
            }
        }

        // Generate bunkers
        for _ in 0..<difficulty.bunkerCount {
            if let position = generateObstaclePosition(
                avoiding: fairwayPath,
                teePosition: teePosition,
                pinPosition: pinPosition,
                worldSize: worldSize
            ) {
                obstacles.append(Obstacle(
                    type: .bunker,
                    position: position,
                    size: CGSize(width: 30 + drand48() * 20, height: 20 + drand48() * 15)
                ))
            }
        }

        // Generate strategic trees - many more and better placed!
        let totalTrees = difficulty.treeCount

        // Place trees in strategic groups
        for i in 0..<totalTrees {
            let position: Position?

            if i < totalTrees / 3 {
                // First third: Trees around tee area (but not blocking)
                position = generateTreeNearTee(
                    teePosition: teePosition,
                    fairwayPath: fairwayPath,
                    worldSize: worldSize
                )
            } else if i < (totalTrees * 2) / 3 {
                // Second third: Trees along fairway sides (guarding the fairway)
                position = generateTreeAlongFairway(
                    teePosition: teePosition,
                    pinPosition: pinPosition,
                    fairwayPath: fairwayPath,
                    worldSize: worldSize
                )
            } else {
                // Final third: Trees around green area
                position = generateTreeNearGreen(
                    pinPosition: pinPosition,
                    fairwayPath: fairwayPath,
                    worldSize: worldSize
                )
            }

            if let treePosition = position {
                // Varied tree sizes for realism
                let treeSize = 12 + drand48() * 16 // 12-28 size trees
                obstacles.append(Obstacle(
                    type: .tree,
                    position: treePosition,
                    size: CGSize(width: treeSize, height: treeSize)
                ))
            }
        }

        return obstacles
    }

    private func generateObstaclePosition(
        avoiding fairwayPath: CGPath,
        teePosition: Position,
        pinPosition: Position,
        worldSize: CGSize,
        maxAttempts: Int = 20
    ) -> Position? {
        for _ in 0..<maxAttempts {
            let x = drand48() * worldSize.width
            let y = teePosition.y + drand48() * (pinPosition.y - teePosition.y)
            let position = Position(x: x, y: y)

            // Check if position is valid (not too close to fairway or important areas)
            if !fairwayPath.contains(position.cgPoint) &&
               !isNearImportantArea(position, teePosition: teePosition, pinPosition: pinPosition) {
                return position
            }
        }

        // Fallback position
        return Position(
            x: worldSize.width * 0.2 + drand48() * worldSize.width * 0.6,
            y: teePosition.y + 0.3 * (pinPosition.y - teePosition.y)
        )
    }

    private func isNearImportantArea(_ position: Position, teePosition: Position, pinPosition: Position) -> Bool {
        let teeDistance = position.distance(to: teePosition)
        let pinDistance = position.distance(to: pinPosition)
        return teeDistance < 80 || pinDistance < 60
    }

    // MARK: - Strategic Tree Placement

    private func generateTreeNearTee(
        teePosition: Position,
        fairwayPath: CGPath,
        worldSize: CGSize,
        maxAttempts: Int = 15
    ) -> Position? {
        for _ in 0..<maxAttempts {
            // Place trees around tee area but not blocking the immediate shot
            let angle = drand48() * 2 * Double.pi
            let distance = 60 + drand48() * 80 // 60-140 points from tee
            let position = Position(
                x: teePosition.x + cos(angle) * distance,
                y: teePosition.y + sin(angle) * distance
            )

            // Make sure it's not on the fairway and within bounds
            if !fairwayPath.contains(position.cgPoint) &&
               position.x > 20 && position.x < worldSize.width - 20 &&
               position.y > 20 && position.y < worldSize.height - 20 {
                return position
            }
        }
        return nil
    }

    private func generateTreeAlongFairway(
        teePosition: Position,
        pinPosition: Position,
        fairwayPath: CGPath,
        worldSize: CGSize,
        maxAttempts: Int = 20
    ) -> Position? {
        for _ in 0..<maxAttempts {
            // Pick a point along the fairway line
            let fairwayProgress = 0.2 + drand48() * 0.6 // 20%-80% along fairway
            let fairwayPoint = Position(
                x: teePosition.x + (pinPosition.x - teePosition.x) * fairwayProgress,
                y: teePosition.y + (pinPosition.y - teePosition.y) * fairwayProgress
            )

            // Place tree to the side of the fairway
            let sideDistance = 40 + drand48() * 60 // 40-100 points from fairway center
            let sideAngle = (drand48() < 0.5 ? -1 : 1) * (Double.pi/2) // Left or right of fairway
            let fairwayDirection = teePosition.direction(to: pinPosition)

            let treePosition = Position(
                x: fairwayPoint.x + cos(Double(fairwayDirection) + sideAngle) * sideDistance,
                y: fairwayPoint.y + sin(Double(fairwayDirection) + sideAngle) * sideDistance
            )

            // Ensure it's not on fairway and within bounds
            if !fairwayPath.contains(treePosition.cgPoint) &&
               treePosition.x > 20 && treePosition.x < worldSize.width - 20 &&
               treePosition.y > 20 && treePosition.y < worldSize.height - 20 {
                return treePosition
            }
        }
        return nil
    }

    private func generateTreeNearGreen(
        pinPosition: Position,
        fairwayPath: CGPath,
        worldSize: CGSize,
        maxAttempts: Int = 15
    ) -> Position? {
        for _ in 0..<maxAttempts {
            // Place trees around green area
            let angle = drand48() * 2 * Double.pi
            let distance = 50 + drand48() * 70 // 50-120 points from pin
            let position = Position(
                x: pinPosition.x + cos(angle) * distance,
                y: pinPosition.y + sin(angle) * distance
            )

            // Don't block the approach to green too much
            let approachDistance = position.distance(to: pinPosition)
            if !fairwayPath.contains(position.cgPoint) &&
               approachDistance > 40 && // Not too close to pin
               position.x > 20 && position.x < worldSize.width - 20 &&
               position.y > 20 && position.y < worldSize.height - 20 {
                return position
            }
        }
        return nil
    }
}