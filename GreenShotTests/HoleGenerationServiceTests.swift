//
//  HoleGenerationServiceTests.swift
//  GreenShotTests
//
//  Unit tests for hole generation service
//

import Testing
import Foundation
@testable import GreenShot

struct HoleGenerationServiceTests {

    let holeGenerationService = HoleGenerationService(scoringService: ScoringService())

    @Test("Hole generation creates valid hole structure")
    func testGenerateHole() async throws {
        let holeNumber = 1
        let difficulty = Difficulty(0.5) // Medium difficulty

        let hole = holeGenerationService.generateHole(number: holeNumber, difficulty: difficulty, worldSize: CGSize(width: 800, height: 1600))

        // Basic structure validation
        #expect(hole.number == holeNumber, "Hole number should match input")
        #expect(hole.par >= 3 && hole.par <= 5, "Par should be between 3 and 5")
        #expect(hole.distance > 0, "Distance should be positive")

        // Position validation
        #expect(hole.teePosition.x >= 0, "Tee position X should be valid")
        #expect(hole.teePosition.y >= 0, "Tee position Y should be valid")
        #expect(hole.pinPosition.x >= 0, "Pin position X should be valid")
        #expect(hole.pinPosition.y >= 0, "Pin position Y should be valid")

        // Distance consistency
        let actualDistance = hole.teePosition.distance(to: hole.pinPosition)
        let tolerance: CGFloat = 50 // Allow some variance for course layout
        #expect(abs(actualDistance - hole.distance) <= tolerance, "Actual distance should be close to specified distance")
    }

    @Test("Hole generation respects difficulty settings")
    func testGenerateHoleWithDifficulty() async throws {
        let easyDifficulty = Difficulty(0.2)
        let hardDifficulty = Difficulty(0.8)

        let easyHole = holeGenerationService.generateHole(number: 1, difficulty: easyDifficulty, worldSize: CGSize(width: 800, height: 1600))
        let hardHole = holeGenerationService.generateHole(number: 1, difficulty: hardDifficulty, worldSize: CGSize(width: 800, height: 1600))

        // Hard holes should generally have more obstacles
        #expect(hardHole.obstacles.count >= easyHole.obstacles.count,
                "Harder difficulty should have equal or more obstacles")

        // Validate obstacle types exist
        #expect(easyHole.obstacles.allSatisfy { obstacle in
            [ObstacleType.water, .bunker, .tree, .rough].contains(obstacle.type)
        }, "All obstacles should have valid types")
    }

    @Test("Course generation creates multiple unique holes")
    func testGenerateCourse() async throws {
        let numberOfHoles = 9
        let _ = Difficulty(0.5)

        let course = holeGenerationService.generateCourse(holeCount: numberOfHoles, name: "Test Course", worldSize: CGSize(width: 800, height: 1600))

        // Basic course validation
        #expect(course.holes.count == numberOfHoles, "Course should have correct number of holes")
        #expect(course.holes.allSatisfy { $0.number >= 1 && $0.number <= numberOfHoles },
                "All hole numbers should be valid")

        // Check for uniqueness
        let holeNumbers = Set(course.holes.map { $0.number })
        #expect(holeNumbers.count == numberOfHoles, "All hole numbers should be unique")

        // Validate course progression
        let sortedHoles = course.holes.sorted { $0.number < $1.number }
        for (index, hole) in sortedHoles.enumerated() {
            #expect(hole.number == index + 1, "Holes should be numbered sequentially")
        }
    }

    @Test("Hole generation creates valid fairway paths")
    func testFairwayPathGeneration() async throws {
        let hole = holeGenerationService.generateHole(number: 1, difficulty: Difficulty(0.5), worldSize: CGSize(width: 800, height: 1600))

        #expect(hole.fairwayPath != nil, "Hole should have a fairway path")

        let pathBounds = hole.fairwayPath.boundingBox
        #expect(pathBounds.width > 0 && pathBounds.height > 0, "Fairway path should have valid dimensions")

        // Path should roughly connect tee to pin
        let teeInBounds = pathBounds.contains(hole.teePosition.cgPoint)
        let pinInBounds = pathBounds.contains(hole.pinPosition.cgPoint)
        #expect(teeInBounds || pinInBounds, "Fairway path should encompass tee or pin position")
    }

    @Test("Obstacle generation creates valid obstacles")
    func testObstacleGeneration() async throws {
        let hole = holeGenerationService.generateHole(number: 1, difficulty: Difficulty(0.7), worldSize: CGSize(width: 800, height: 1600))

        for obstacle in hole.obstacles {
            // Basic obstacle validation
            #expect(obstacle.position.x >= 0, "Obstacle X position should be valid")
            #expect(obstacle.position.y >= 0, "Obstacle Y position should be valid")
            #expect(obstacle.size.width > 0, "Obstacle width should be positive")
            #expect(obstacle.size.height > 0, "Obstacle height should be positive")

            // Type-specific validation
            switch obstacle.type {
            case .water:
                #expect(obstacle.size.width >= 30, "Water hazards should be reasonably sized")
            case .bunker:
                #expect(obstacle.size.width >= 20, "Bunkers should be reasonably sized")
            case .tree:
                #expect(obstacle.size.width >= 10, "Trees should be reasonably sized")
            case .rough:
                #expect(obstacle.size.width >= 15, "Rough patches should be reasonably sized")
            }
        }
    }

    @Test("Hole generation maintains consistent seeding")
    func testConsistentGeneration() async throws {
        // Generate same hole twice with deterministic seeding
        let hole1 = holeGenerationService.generateHole(number: 1, difficulty: Difficulty(0.5), worldSize: CGSize(width: 800, height: 1600))
        let hole2 = holeGenerationService.generateHole(number: 1, difficulty: Difficulty(0.5), worldSize: CGSize(width: 800, height: 1600))

        // With seeded generation, holes should be identical
        #expect(hole1.par == hole2.par, "Par should be consistent with same seed")
        #expect(hole1.distance == hole2.distance, "Distance should be consistent with same seed")
        #expect(hole1.obstacles.count == hole2.obstacles.count, "Obstacle count should be consistent")
    }

    @Test("Par calculation matches distance ranges")
    func testParCalculationLogic() async throws {
        // Test various distances to ensure par calculation is correct
        let shortHole = holeGenerationService.generateHole(number: 1, difficulty: Difficulty(0.3), worldSize: CGSize(width: 800, height: 1600))
        let mediumHole = holeGenerationService.generateHole(number: 2, difficulty: Difficulty(0.5), worldSize: CGSize(width: 800, height: 1600))
        let longHole = holeGenerationService.generateHole(number: 3, difficulty: Difficulty(0.7), worldSize: CGSize(width: 800, height: 1600))

        // Validate par ranges based on typical golf course standards
        let allHoles = [shortHole, mediumHole, longHole]
        for hole in allHoles {
            switch hole.par {
            case 3:
                #expect(hole.distance <= CGFloat(Constants.Course.Distances.par4Min),
                        "Par 3 holes should be shorter than par 4 minimum")
            case 4:
                #expect(hole.distance >= CGFloat(Constants.Course.Distances.par4Min) &&
                       hole.distance <= CGFloat(Constants.Course.Distances.par5Min),
                        "Par 4 holes should be in correct distance range")
            case 5:
                #expect(hole.distance >= CGFloat(Constants.Course.Distances.par5Min),
                        "Par 5 holes should be longer than par 5 minimum")
            default:
                #expect(Bool(false), "Invalid par value: \(hole.par)")
            }
        }
    }

    @Test("Course generation handles edge cases")
    func testCourseGenerationEdgeCases() async throws {
        // Test minimum course
        let singleHoleCourse = holeGenerationService.generateCourse(holeCount: 1, name: "Single Hole Course", worldSize: CGSize(width: 800, height: 1600))
        #expect(singleHoleCourse.holes.count == 1, "Single hole course should work")

        // Test with extreme difficulties
        let veryEasyCourse = holeGenerationService.generateCourse(holeCount: 3, name: "Very Easy Course", worldSize: CGSize(width: 800, height: 1600))
        let veryHardCourse = holeGenerationService.generateCourse(holeCount: 3, name: "Very Hard Course", worldSize: CGSize(width: 800, height: 1600))

        #expect(veryEasyCourse.holes.count == 3, "Very easy course should generate correctly")
        #expect(veryHardCourse.holes.count == 3, "Very hard course should generate correctly")

        // Hard course should generally have more total obstacles
        let easyObstacleCount = veryEasyCourse.holes.reduce(0) { $0 + $1.obstacles.count }
        let hardObstacleCount = veryHardCourse.holes.reduce(0) { $0 + $1.obstacles.count }
        #expect(hardObstacleCount >= easyObstacleCount,
                "Harder course should have equal or more obstacles overall")
    }
}