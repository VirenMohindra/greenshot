//
//  PositionTests.swift
//  GreenShotTests
//
//  Unit tests for Position value object
//

import Testing
import Foundation
@testable import runner

struct PositionTests {

    @Test("Position initializes correctly with x and y coordinates")
    func testPositionInitialization() async throws {
        let position = Position(x: 100.5, y: 200.75)

        #expect(position.x == 100.5, "X coordinate should be set correctly")
        #expect(position.y == 200.75, "Y coordinate should be set correctly")
    }

    @Test("Position converts to CGPoint correctly")
    func testCGPointConversion() async throws {
        let position = Position(x: 150, y: 250)
        let cgPoint = position.cgPoint

        #expect(cgPoint.x == 150, "CGPoint X should match position X")
        #expect(cgPoint.y == 250, "CGPoint Y should match position Y")
    }

    @Test("Position initializes from CGPoint correctly")
    func testInitFromCGPoint() async throws {
        let cgPoint = CGPoint(x: 75.5, y: 125.25)
        let position = Position(cgPoint)

        #expect(position.x == 75.5, "Position X should match CGPoint X")
        #expect(position.y == 125.25, "Position Y should match CGPoint Y")
    }

    @Test("Position calculates distance correctly")
    func testDistanceCalculation() async throws {
        let position1 = Position(x: 0, y: 0)
        let position2 = Position(x: 3, y: 4)

        let distance = position1.distance(to: position2)

        #expect(TestAssertions.assertCGFloatEqual(distance, 5.0), "Distance should be 5.0 (3-4-5 triangle)")
    }

    @Test("Position calculates distance to self as zero")
    func testDistanceToSelf() async throws {
        let position = Position(x: 100, y: 200)
        let distance = position.distance(to: position)

        #expect(distance == 0, "Distance to self should be zero")
    }

    @Test("Position calculates direction correctly")
    func testDirectionCalculation() async throws {
        let start = Position(x: 0, y: 0)
        let end = Position(x: 100, y: 0)

        let direction = start.direction(to: end)

        #expect(TestAssertions.assertCGFloatEqual(direction, 0), "Direction should be 0 radians (rightward)")
    }

    @Test("Position calculates vertical direction correctly")
    func testVerticalDirection() async throws {
        let start = Position(x: 0, y: 0)
        let upward = Position(x: 0, y: 100)

        let direction = start.direction(to: upward)

        #expect(TestAssertions.assertCGFloatEqual(direction, CGFloat.pi / 2), "Direction should be π/2 radians (upward)")
    }

    @Test("Position direction to self returns zero")
    func testDirectionToSelf() async throws {
        let position = Position(x: 50, y: 50)
        let direction = position.direction(to: position)

        #expect(direction == 0, "Direction to self should be zero")
    }

    @Test("Position supports Equatable protocol")
    func testEquatable() async throws {
        let position1 = Position(x: 100, y: 200)
        let position2 = Position(x: 100, y: 200)
        let position3 = Position(x: 101, y: 200)

        #expect(position1 == position2, "Identical positions should be equal")
        #expect(position1 != position3, "Different positions should not be equal")
    }

    @Test("Position handles negative coordinates")
    func testNegativeCoordinates() async throws {
        let position = Position(x: -50, y: -75)

        #expect(position.x == -50, "Negative X should be handled correctly")
        #expect(position.y == -75, "Negative Y should be handled correctly")
    }

    @Test("Position calculates distance with negative coordinates")
    func testDistanceWithNegativeCoordinates() async throws {
        let position1 = Position(x: -3, y: -4)
        let position2 = Position(x: 0, y: 0)

        let distance = position1.distance(to: position2)

        #expect(TestAssertions.assertCGFloatEqual(distance, 5.0), "Distance calculation should work with negative coordinates")
    }

    @Test("Position handles very large coordinates")
    func testLargeCoordinates() async throws {
        let position = Position(x: 1_000_000, y: 2_000_000)

        #expect(position.x == 1_000_000, "Large X coordinate should be handled")
        #expect(position.y == 2_000_000, "Large Y coordinate should be handled")
    }

    @Test("Position handles floating point precision")
    func testFloatingPointPrecision() async throws {
        let position1 = Position(x: 0.1 + 0.2, y: 0.4 + 0.5)
        let position2 = Position(x: 0.3, y: 0.9)

        // Use tolerance for floating point comparison
        #expect(TestAssertions.assertPositionsEqual(position1, position2, tolerance: 0.0001),
                "Floating point positions should be equal within tolerance")
    }

    @Test("Position direction calculation handles quadrants correctly")
    func testDirectionQuadrants() async throws {
        let origin = Position(x: 0, y: 0)

        // First quadrant (positive x, positive y)
        let q1 = Position(x: 1, y: 1)
        let direction1 = origin.direction(to: q1)
        #expect(direction1 > 0 && direction1 < CGFloat.pi / 2, "First quadrant direction should be 0 < θ < π/2")

        // Second quadrant (negative x, positive y)
        let q2 = Position(x: -1, y: 1)
        let direction2 = origin.direction(to: q2)
        #expect(direction2 > CGFloat.pi / 2 && direction2 < CGFloat.pi, "Second quadrant direction should be π/2 < θ < π")

        // Third quadrant (negative x, negative y)
        let q3 = Position(x: -1, y: -1)
        let direction3 = origin.direction(to: q3)
        #expect(direction3 < -CGFloat.pi / 2 && direction3 > -CGFloat.pi, "Third quadrant direction should be -π < θ < -π/2")

        // Fourth quadrant (positive x, negative y)
        let q4 = Position(x: 1, y: -1)
        let direction4 = origin.direction(to: q4)
        #expect(direction4 < 0 && direction4 > -CGFloat.pi / 2, "Fourth quadrant direction should be -π/2 < θ < 0")
    }

    @Test("Position calculates midpoint correctly")
    func testMidpointCalculation() async throws {
        let position1 = Position(x: 0, y: 0)
        let position2 = Position(x: 100, y: 200)

        let midpoint = Position(
            x: (position1.x + position2.x) / 2,
            y: (position1.y + position2.y) / 2
        )

        #expect(midpoint.x == 50, "Midpoint X should be average of endpoints")
        #expect(midpoint.y == 100, "Midpoint Y should be average of endpoints")
    }

    @Test("Position validates within bounds correctly")
    func testBoundsValidation() async throws {
        let bounds = CGSize(width: 800, height: 600)

        let validPosition = Position(x: 400, y: 300)
        let invalidXPosition = Position(x: 900, y: 300)
        let invalidYPosition = Position(x: 400, y: 700)
        let negativePosition = Position(x: -10, y: 50)

        #expect(TestAssertions.assertPositionValid(validPosition, within: bounds),
                "Valid position should be within bounds")
        #expect(!TestAssertions.assertPositionValid(invalidXPosition, within: bounds),
                "Position with X > width should be invalid")
        #expect(!TestAssertions.assertPositionValid(invalidYPosition, within: bounds),
                "Position with Y > height should be invalid")
        #expect(!TestAssertions.assertPositionValid(negativePosition, within: bounds),
                "Negative position should be invalid")
    }
}