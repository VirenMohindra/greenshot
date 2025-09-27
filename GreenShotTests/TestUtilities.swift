//
//  TestUtilities.swift
//  GreenShotTests
//
//  Shared utilities and fixtures for all test suites
//

import Foundation
import UIKit
@testable import GreenShot

// MARK: - Test Fixtures
struct TestFixtures {

    // MARK: - Position Fixtures
    static let origin = Position(x: 0, y: 0)
    static let teePosition = Position(x: 100, y: 100)
    static let pinPosition = Position(x: 400, y: 800)
    static let outOfBounds = Position(x: -50, y: -50)

    // MARK: - Velocity Fixtures
    static let stationaryVelocity = Velocity(dx: 0.01, dy: 0.01) // Below threshold
    static let slowVelocity = Velocity(dx: 1.0, dy: 1.0)
    static let fastVelocity = Velocity(dx: 10.0, dy: 10.0)
    static let maxVelocity = Velocity(dx: CGFloat(Constants.Physics.maxShotVelocity), dy: 0)

    // MARK: - Difficulty Fixtures
    static let easyDifficulty = Difficulty(0.2)
    static let mediumDifficulty = Difficulty(0.5)
    static let hardDifficulty = Difficulty(0.8)
    static let extremeDifficulty = Difficulty(1.0)

    // MARK: - Hole Fixtures
    static func createTestHole(number: Int = 1, par: Int = 4, distance: CGFloat = 300) -> Hole {
        return Hole(
            number: number,
            par: par,
            difficulty: mediumDifficulty,
            teePosition: teePosition,
            pinPosition: pinPosition,
            fairwayPath: TestFixtures.createTestFairwayPath(),
            obstacles: createTestObstacles()
        )
    }

    static func createTestFairwayPath() -> CGPath {
        let path = CGMutablePath()
        path.move(to: teePosition.cgPoint)
        path.addLine(to: CGPoint(x: 200, y: 400))
        path.addLine(to: pinPosition.cgPoint)
        path.addLine(to: CGPoint(x: teePosition.x + 40, y: teePosition.y))
        path.closeSubpath()
        return path
    }

    static func createTestObstacles() -> [Obstacle] {
        return [
            Obstacle(
                type: .bunker,
                position: Position(x: 150, y: 200),
                size: CGSize(width: 40, height: 30)
            ),
            Obstacle(
                type: .tree,
                position: Position(x: 250, y: 350),
                size: CGSize(width: 20, height: 20)
            ),
            Obstacle(
                type: .water,
                position: Position(x: 180, y: 600),
                size: CGSize(width: 60, height: 40)
            )
        ]
    }

    // MARK: - Course Fixtures
    static func createTestCourse(holeCount: Int = 9) -> Course {
        let holes = (1...holeCount).map { holeNumber in
            createTestHole(number: holeNumber, par: [3, 4, 5].randomElement()!, distance: CGFloat.random(in: 150...500))
        }
        return Course(
            name: "Test Course",
            holes: holes,
            worldSize: CGSize(width: 800, height: 1600)
        )
    }

    // MARK: - Player Fixtures
    static func createTestPlayer(name: String = "Test Player") -> Player {
        return Player(displayName: name)
    }

    // MARK: - GolfBall Fixtures
    static func createTestBall(at position: Position = teePosition) -> GolfBall {
        return GolfBall(position: position)
    }

    // MARK: - Score Fixtures
    static let eagleScore = Score(strokes: 3, par: 5)  // -2
    static let birdieScore = Score(strokes: 3, par: 4) // -1
    static let parScore = Score(strokes: 4, par: 4)    //  0
    static let bogeyScore = Score(strokes: 5, par: 4)  // +1
    static let doubleBogeyScore = Score(strokes: 6, par: 4) // +2

    // MARK: - Shot Fixtures
    static func createTestShot(power: CGFloat = 0.5, direction: CGFloat = 0) -> Shot {
        return Shot(
            holeNumber: 1,
            strokeNumber: 1,
            startPosition: teePosition,
            power: power,
            direction: direction
        )
    }
}

// MARK: - Test Assertions
struct TestAssertions {

    // MARK: - Position Assertions
    static func assertPositionsEqual(_ position1: Position, _ position2: Position, tolerance: CGFloat = 0.001) -> Bool {
        return abs(position1.x - position2.x) <= tolerance && abs(position1.y - position2.y) <= tolerance
    }

    static func assertPositionValid(_ position: Position, within bounds: CGSize) -> Bool {
        return position.x >= 0 && position.y >= 0 &&
               position.x <= bounds.width && position.y <= bounds.height
    }

    // MARK: - Velocity Assertions
    static func assertVelocitiesEqual(_ velocity1: Velocity, _ velocity2: Velocity, tolerance: CGFloat = 0.001) -> Bool {
        return abs(velocity1.dx - velocity2.dx) <= tolerance && abs(velocity1.dy - velocity2.dy) <= tolerance
    }

    static func assertVelocityWithinBounds(_ velocity: Velocity, maxMagnitude: CGFloat = CGFloat(Constants.Physics.maxShotVelocity)) -> Bool {
        return velocity.magnitude <= maxMagnitude
    }

    // MARK: - Score Assertions
    static func assertScoreType(_ score: Score, expectedType: ScoreType) -> Bool {
        switch expectedType {
        case .eagle: return score.isEagle
        case .birdie: return score.isBirdie
        case .par: return score.isPar
        case .bogey: return score.isBogey
        case .doubleBogey: return score.isDoubleBogey
        }
    }

    // MARK: - Range Assertions
    static func assertValueInRange<T: Comparable>(_ value: T, min: T, max: T) -> Bool {
        return value >= min && value <= max
    }

    static func assertFloatEqual(_ value1: Float, _ value2: Float, tolerance: Float = 0.001) -> Bool {
        return abs(value1 - value2) <= tolerance
    }

    static func assertCGFloatEqual(_ value1: CGFloat, _ value2: CGFloat, tolerance: CGFloat = 0.001) -> Bool {
        return abs(value1 - value2) <= tolerance
    }
}

// MARK: - Score Type Enum
enum ScoreType {
    case eagle, birdie, par, bogey, doubleBogey
}

// MARK: - Mock Service Factory
class MockServiceFactory {

    static func createMockPhysicsService() -> MockPhysicsService {
        return MockPhysicsService()
    }

    static func createMockScoringService() -> MockScoringService {
        return MockScoringService()
    }

    static func createMockHoleGenerationService() -> MockHoleGenerationService {
        return MockHoleGenerationService()
    }

    static func createMockPersistenceService() -> PersistenceServiceProtocol {
        // Use the mock from the main code
        return runner.MockPersistenceService()
    }
}

// MARK: - Mock Services
class MockPhysicsService: PhysicsServiceProtocol {
    var calculateShotImpulseCalled = false
    var applyDampingCalled = false
    var calculateTrajectoryCalled = false

    var mockImpulse = Velocity(dx: 5.0, dy: 0.0)
    var mockDampedVelocity = Velocity(dx: 2.0, dy: 0.0)
    var mockTrajectory: [Position] = [TestFixtures.teePosition, TestFixtures.pinPosition]

    func calculateShotImpulse(from dragStart: Position, to dragEnd: Position, power: CGFloat) -> Velocity {
        calculateShotImpulseCalled = true
        return mockImpulse
    }

    func simulateTrajectory(from position: Position, with velocity: Velocity, timeStep: CGFloat, maxSteps: Int) -> [Position] {
        calculateTrajectoryCalled = true
        return mockTrajectory
    }

    func applyDamping(to velocity: Velocity, damping: CGFloat) -> Velocity {
        applyDampingCalled = true
        return mockDampedVelocity
    }

    func isColliding(ballPosition: Position, ballRadius: CGFloat, obstacle: Obstacle) -> Bool {
        return false
    }

    func calculateCollisionResponse(ballVelocity: Velocity, obstacle: Obstacle) -> Velocity {
        return ballVelocity
    }

    func isBallStationary(_ velocity: Velocity) -> Bool {
        return velocity.magnitude < 0.01
    }
}

class MockScoringService: ScoringServiceProtocol {
    var calculateParCalled = false
    var createScoreCalled = false

    var mockPar = 4
    var mockScore = TestFixtures.parScore
    var mockCelebrationLevel = CelebrationLevel.moderate

    func calculateParForDistance(_ distance: CGFloat, difficulty: Difficulty) -> Int {
        calculateParCalled = true
        return mockPar
    }

    func createScore(strokes: Int, par: Int) -> Score {
        createScoreCalled = true
        return mockScore
    }

    func getScoreColor(for score: Score) -> UIColor {
        return .white
    }

    func getScoreDisplayColor(for score: Score) -> UIColor {
        return .white
    }

    func shouldCelebrate(_ score: Score) -> Bool {
        return score.isBirdie || score.isEagle
    }

    func getCelebrationLevel(_ score: Score) -> CelebrationLevel {
        return mockCelebrationLevel
    }
}

class MockHoleGenerationService: HoleGenerationServiceProtocol {
    var generateHoleCalled = false
    var generateCourseCalled = false

    var mockHole = TestFixtures.createTestHole()
    var mockCourse = TestFixtures.createTestCourse()

    func generateHole(number: Int, difficulty: Difficulty, worldSize: CGSize) -> Hole {
        generateHoleCalled = true
        return mockHole
    }

    func generateCourse(holeCount: Int, name: String, worldSize: CGSize) -> Course {
        generateCourseCalled = true
        return mockCourse
    }

    func setSeed(_ seed: UInt64) {
        // Mock implementation - no-op
    }
}


// MARK: - Test Performance Utilities
struct PerformanceTestUtilities {

    static func measureExecutionTime<T>(operation: () throws -> T) rethrows -> (result: T, timeInterval: TimeInterval) {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
        return (result, timeElapsed)
    }

    static func assertPerformance<T>(operation: () throws -> T, maxTime: TimeInterval, description: String) rethrows -> T {
        let (result, elapsed) = try measureExecutionTime(operation: operation)
        assert(elapsed <= maxTime, "\(description) took \(elapsed)s, expected <= \(maxTime)s")
        return result
    }
}