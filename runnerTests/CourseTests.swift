//
//  CourseTests.swift
//  GreenShotTests
//
//  Unit tests for Course entity
//

import Testing
import Foundation
@testable import runner

struct CourseTests {

    @Test("Course initializes correctly with holes")
    func testCourseInitialization() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        #expect(course.holes.count == 9, "Course should have correct number of holes")
        #expect(course.name == "Test Course", "Course should have correct name")
        #expect(course.worldSize.width == 800, "Course should have correct world width")
        #expect(course.worldSize.height == 1600, "Course should have correct world height")
        #expect(course.totalHoles == 9, "Total holes should match hole count")
    }

    @Test("Course validates hole sequence")
    func testHoleSequenceValidation() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Check that holes are numbered sequentially
        let sortedHoles = course.holes.sorted { $0.number < $1.number }
        for (index, hole) in sortedHoles.enumerated() {
            #expect(hole.number == index + 1, "Hole \(index + 1) should be numbered correctly")
        }
    }

    @Test("Course provides current hole correctly")
    func testCurrentHoleNavigation() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Initially should be on hole 1
        let firstHole = course.currentHole
        #expect(firstHole?.number == 1, "Should start on hole 1")

        // Navigate to next hole
        let secondHole = course.moveToNextHole()
        #expect(secondHole?.number == 2, "Should move to hole 2")
        #expect(course.currentHole?.number == 2, "Current hole should be hole 2")

        // Navigate to specific hole
        let fifthHole = course.moveToHole(5)
        #expect(fifthHole?.number == 5, "Should move to hole 5")
        #expect(course.currentHole?.number == 5, "Current hole should be hole 5")
    }

    @Test("Course handles hole navigation bounds")
    func testHoleNavigationBounds() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Navigate to last hole
        let lastHole = course.moveToHole(9)
        #expect(lastHole?.number == 9, "Should be on hole 9")
        #expect(course.isOnLastHole, "Should be on last hole")

        // Try to move past last hole
        let beyondLast = course.moveToNextHole()
        #expect(beyondLast == nil, "Should return nil when moving past last hole")
        #expect(course.isComplete, "Course should be complete after moving past last hole")

        // Navigate to first hole
        let firstHole = course.moveToHole(1)
        #expect(firstHole?.number == 1, "Should be on hole 1")

        // Try to move before first hole
        let beforeFirst = course.moveToPreviousHole()
        #expect(beforeFirst == nil, "Should return nil when moving before first hole")
        #expect(course.currentHole?.number == 1, "Should stay on hole 1 when at beginning")
    }

    @Test("Course calculates total par correctly")
    func testTotalParCalculation() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)
        let totalPar = course.totalPar

        let expectedPar = course.holes.reduce(0) { $0 + $1.par }
        #expect(totalPar == expectedPar, "Total par should equal sum of all hole pars")

        // Typical 9-hole course should be around par 35-37
        #expect(totalPar >= 27, "Total par should be reasonable for 9 holes (minimum)")
        #expect(totalPar <= 45, "Total par should be reasonable for 9 holes (maximum)")
    }

    @Test("Course calculates total distance correctly")
    func testTotalDistanceCalculation() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Calculate total distance manually since Course doesn't have this property
        let totalDistance = course.holes.reduce(CGFloat(0)) { $0 + $1.distance }

        // Reasonable distance for 9-hole course
        #expect(totalDistance >= 1500, "Total distance should be reasonable (minimum)")
        #expect(totalDistance <= 4500, "Total distance should be reasonable (maximum)")
    }

    @Test("Course progress tracking")
    func testProgressTracking() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        #expect(course.currentHole?.number == 1, "Should start on hole 1")
        #expect(!course.isComplete, "Course should not be completed initially")

        // Navigate through holes
        for holeNumber in 2...9 {
            let nextHole = course.moveToNextHole()
            #expect(nextHole?.number == holeNumber, "Should advance to hole \(holeNumber)")
        }

        // Try to move past last hole
        let beyondLast = course.moveToNextHole()
        #expect(beyondLast == nil, "Should return nil when moving past last hole")
        #expect(course.isComplete, "Course should be completed")
    }

    @Test("Course navigation between holes")
    func testHoleNavigation() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Test next hole property
        #expect(course.nextHole?.number == 2, "Next hole should be hole 2")

        // Move to middle hole
        course.moveToHole(5)
        #expect(course.currentHole?.number == 5, "Should be on hole 5")
        #expect(course.nextHole?.number == 6, "Next hole should be hole 6")

        // Move to last hole
        course.moveToHole(9)
        #expect(course.currentHole?.number == 9, "Should be on hole 9")
        #expect(course.nextHole == nil, "Next hole should be nil on last hole")
    }

    @Test("Course statistics and properties")
    func testCourseStatistics() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Test average par calculation
        let averagePar = course.averagePar
        let expectedAverage = Double(course.totalPar) / Double(course.holes.count)
        #expect(TestAssertions.assertFloatEqual(Float(averagePar), Float(expectedAverage)),
                "Average par should be calculated correctly")

        // Test par count properties
        let parThreeCount = course.parThreeCount
        let parFourCount = course.parFourCount
        let parFiveCount = course.parFiveCount

        #expect(parThreeCount + parFourCount + parFiveCount == course.totalHoles,
                "Par counts should add up to total holes")
        #expect(parThreeCount >= 0, "Par 3 count should be non-negative")
        #expect(parFourCount >= 0, "Par 4 count should be non-negative")
        #expect(parFiveCount >= 0, "Par 5 count should be non-negative")
    }

    @Test("Course difficulty distribution")
    func testDifficultyDistribution() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        let distribution = course.difficultyDistribution
        let totalHoles = distribution.beginner + distribution.intermediate + distribution.advanced

        #expect(totalHoles == course.totalHoles, "Difficulty distribution should add up to total holes")
        #expect(distribution.beginner >= 0, "Beginner holes count should be non-negative")
        #expect(distribution.intermediate >= 0, "Intermediate holes count should be non-negative")
        #expect(distribution.advanced >= 0, "Advanced holes count should be non-negative")
    }

    @Test("Course reset functionality")
    func testCourseReset() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Navigate to middle hole
        course.moveToHole(5)
        #expect(course.currentHole?.number == 5, "Should be on hole 5 before reset")

        // Reset course
        course.reset()

        #expect(course.currentHole?.number == 1, "Should return to hole 1 after reset")
        #expect(!course.isComplete, "Should not be completed after reset")
    }

    @Test("Course world bounds validation")
    func testWorldBoundsValidation() async throws {
        let course = TestFixtures.createTestCourse()

        for hole in course.holes {
            #expect(TestAssertions.assertPositionValid(hole.teePosition, within: course.worldSize),
                    "Hole \(hole.number) tee should be within world bounds")
            #expect(TestAssertions.assertPositionValid(hole.pinPosition, within: course.worldSize),
                    "Hole \(hole.number) pin should be within world bounds")

            for obstacle in hole.obstacles {
                #expect(TestAssertions.assertPositionValid(obstacle.position, within: course.worldSize),
                        "Obstacle in hole \(hole.number) should be within world bounds")
            }
        }
    }

    @Test("Course supports different hole counts")
    func testDifferentHoleCounts() async throws {
        let course3 = TestFixtures.createTestCourse(holeCount: 3)
        let course9 = TestFixtures.createTestCourse(holeCount: 9)
        let course18 = TestFixtures.createTestCourse(holeCount: 18)

        #expect(course3.holes.count == 3, "3-hole course should have 3 holes")
        #expect(course9.holes.count == 9, "9-hole course should have 9 holes")
        #expect(course18.holes.count == 18, "18-hole course should have 18 holes")

        // Validate hole numbering for each
        for course in [course3, course9, course18] {
            let numbers = Set(course.holes.map { $0.number })
            let expectedNumbers = Set(1...course.holes.count)
            #expect(numbers == expectedNumbers, "Course should have consecutively numbered holes")
        }
    }

    @Test("Course par distribution")
    func testParDistribution() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 18)

        let parCounts = course.holes.reduce(into: [Int: Int]()) { counts, hole in
            counts[hole.par, default: 0] += 1
        }

        #expect(parCounts[3] != nil, "Course should have some par 3 holes")
        #expect(parCounts[4] != nil, "Course should have some par 4 holes")
        #expect(parCounts[5] != nil, "Course should have some par 5 holes")

        // Typical 18-hole course distribution
        if course.holes.count == 18 {
            let par3Count = parCounts[3] ?? 0
            let par4Count = parCounts[4] ?? 0
            let par5Count = parCounts[5] ?? 0

            #expect(par3Count >= 2 && par3Count <= 6, "Should have reasonable number of par 3s")
            #expect(par4Count >= 8 && par4Count <= 14, "Should have reasonable number of par 4s")
            #expect(par5Count >= 2 && par5Count <= 6, "Should have reasonable number of par 5s")
        }
    }

    @Test("Course progress description")
    func testProgressDescription() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Test initial progress
        let initialProgress = course.progressDescription
        #expect(initialProgress.contains("1"), "Progress should mention hole 1")
        #expect(initialProgress.contains("9"), "Progress should mention total holes")

        // Test middle progress
        course.moveToHole(5)
        let middleProgress = course.progressDescription
        #expect(middleProgress.contains("5"), "Progress should mention hole 5")

        // Test completion
        course.moveToNextHole() // Move past last hole
        let completedProgress = course.progressDescription
        #expect(completedProgress.contains("Complete"), "Progress should indicate completion")
    }

    @Test("Course front and back nine")
    func testFrontAndBackNine() async throws {
        let course18 = TestFixtures.createTestCourse(holeCount: 18)
        let course9 = TestFixtures.createTestCourse(holeCount: 9)

        // Test 18-hole course
        let frontNine = course18.frontNine
        let backNine = course18.backNine

        #expect(frontNine.count == 9, "Front nine should have 9 holes")
        #expect(backNine.count == 9, "Back nine should have 9 holes")
        #expect(frontNine.first?.number == 1, "Front nine should start with hole 1")
        #expect(frontNine.last?.number == 9, "Front nine should end with hole 9")
        #expect(backNine.first?.number == 10, "Back nine should start with hole 10")
        #expect(backNine.last?.number == 18, "Back nine should end with hole 18")

        // Test 9-hole course
        let frontNineOnly = course9.frontNine
        let backNineEmpty = course9.backNine

        #expect(frontNineOnly.count == 9, "9-hole course should have 9 holes in front nine")
        #expect(backNineEmpty.isEmpty, "9-hole course should have empty back nine")
    }

    @Test("Course performance with large hole counts")
    func testPerformanceWithLargeHoleCounts() async throws {
        let (course, elapsed) = PerformanceTestUtilities.measureExecutionTime {
            return TestFixtures.createTestCourse(holeCount: 36) // Double round
        }

        #expect(elapsed < 2.0, "Creating 36-hole course should complete in under 2 seconds")
        #expect(course.holes.count == 36, "Course should have all 36 holes")
    }

    @Test("Course hole validation")
    func testHoleValidation() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 9)

        // Validate all holes have proper values
        for hole in course.holes {
            #expect(hole.par >= 3 && hole.par <= 5, "Hole \(hole.number) should have valid par")
            #expect(hole.distance > 0, "Hole \(hole.number) should have positive distance")
            #expect(hole.number >= 1 && hole.number <= 9, "Hole \(hole.number) should have valid number")
        }
    }

    @Test("Course navigation edge cases")
    func testNavigationEdgeCases() async throws {
        let course = TestFixtures.createTestCourse(holeCount: 3)

        // Test moving to invalid hole numbers
        let invalidHole = course.moveToHole(0)
        #expect(invalidHole == nil, "Should return nil for hole 0")

        let tooHighHole = course.moveToHole(10)
        #expect(tooHighHole == nil, "Should return nil for hole number too high")

        let negativeHole = course.moveToHole(-1)
        #expect(negativeHole == nil, "Should return nil for negative hole number")

        // Current hole should remain unchanged
        #expect(course.currentHole?.number == 1, "Current hole should remain hole 1 after invalid moves")
    }
}