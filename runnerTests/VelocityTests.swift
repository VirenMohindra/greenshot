//
//  VelocityTests.swift
//  GreenShotTests
//
//  Unit tests for Velocity value object
//

import Testing
import Foundation
@testable import runner

struct VelocityTests {

    @Test("Velocity initializes correctly with dx and dy components")
    func testVelocityInitialization() async throws {
        let velocity = Velocity(dx: 10.5, dy: -5.25)

        #expect(velocity.dx == 10.5, "X component should be set correctly")
        #expect(velocity.dy == -5.25, "Y component should be set correctly")
    }

    @Test("Velocity initializes from CGVector correctly")
    func testInitFromCGVector() async throws {
        let cgVector = CGVector(dx: 7.5, dy: 12.25)
        let velocity = Velocity(cgVector)

        #expect(velocity.dx == 7.5, "X component should match CGVector dx")
        #expect(velocity.dy == 12.25, "Y component should match CGVector dy")
    }

    @Test("Velocity converts to CGVector correctly")
    func testCGVectorConversion() async throws {
        let velocity = Velocity(dx: 15.0, dy: -8.0)
        let cgVector = velocity.cgVector

        #expect(cgVector.dx == 15.0, "CGVector dx should match velocity dx")
        #expect(cgVector.dy == -8.0, "CGVector dy should match velocity dy")
    }

    @Test("Velocity calculates magnitude correctly")
    func testMagnitudeCalculation() async throws {
        let velocity = Velocity(dx: 3.0, dy: 4.0)
        let magnitude = velocity.magnitude

        #expect(TestAssertions.assertCGFloatEqual(magnitude, 5.0), "Magnitude should be 5.0 (3-4-5 triangle)")
    }

    @Test("Velocity magnitude for zero velocity is zero")
    func testZeroVelocityMagnitude() async throws {
        let velocity = Velocity(dx: 0, dy: 0)
        let magnitude = velocity.magnitude

        #expect(magnitude == 0, "Zero velocity should have zero magnitude")
    }

    @Test("Velocity magnitude is always positive")
    func testMagnitudeAlwaysPositive() async throws {
        let negativeVelocity = Velocity(dx: -6.0, dy: -8.0)
        let magnitude = negativeVelocity.magnitude

        #expect(magnitude > 0, "Magnitude should always be positive")
        #expect(TestAssertions.assertCGFloatEqual(magnitude, 10.0), "Magnitude should be 10.0 regardless of sign")
    }

    @Test("Velocity detects stationary state correctly")
    func testStationaryDetection() async throws {
        let stationaryVelocity = Velocity(dx: 0.05, dy: 0.03) // Below threshold
        let movingVelocity = Velocity(dx: 1.0, dy: 0.5)        // Above threshold

        #expect(stationaryVelocity.isStationary, "Low velocity should be considered stationary")
        #expect(!movingVelocity.isStationary, "High velocity should not be considered stationary")
    }

    @Test("Velocity stationary threshold matches constants")
    func testStationaryThreshold() async throws {
        let thresholdVelocity = Velocity(dx: Constants.Ball.stationaryThreshold, dy: 0)
        let belowThreshold = Velocity(dx: Constants.Ball.stationaryThreshold - 0.01, dy: 0)
        let aboveThreshold = Velocity(dx: Constants.Ball.stationaryThreshold + 0.01, dy: 0)

        #expect(thresholdVelocity.isStationary, "Velocity at threshold should be stationary")
        #expect(belowThreshold.isStationary, "Velocity below threshold should be stationary")
        #expect(!aboveThreshold.isStationary, "Velocity above threshold should not be stationary")
    }

    @Test("Velocity supports Equatable protocol")
    func testEquatable() async throws {
        let velocity1 = Velocity(dx: 5.0, dy: 10.0)
        let velocity2 = Velocity(dx: 5.0, dy: 10.0)
        let velocity3 = Velocity(dx: 5.1, dy: 10.0)

        #expect(velocity1 == velocity2, "Identical velocities should be equal")
        #expect(velocity1 != velocity3, "Different velocities should not be equal")
    }

    @Test("Velocity handles zero components")
    func testZeroComponents() async throws {
        let xOnlyVelocity = Velocity(dx: 5.0, dy: 0)
        let yOnlyVelocity = Velocity(dx: 0, dy: 5.0)
        let zeroVelocity = Velocity(dx: 0, dy: 0)

        #expect(TestAssertions.assertCGFloatEqual(xOnlyVelocity.magnitude, 5.0), "X-only velocity magnitude should be correct")
        #expect(TestAssertions.assertCGFloatEqual(yOnlyVelocity.magnitude, 5.0), "Y-only velocity magnitude should be correct")
        #expect(zeroVelocity.magnitude == 0, "Zero velocity magnitude should be zero")
    }

    @Test("Velocity handles negative components")
    func testNegativeComponents() async throws {
        let negativeVelocity = Velocity(dx: -3.0, dy: -4.0)

        #expect(negativeVelocity.dx == -3.0, "Negative X component should be preserved")
        #expect(negativeVelocity.dy == -4.0, "Negative Y component should be preserved")
        #expect(TestAssertions.assertCGFloatEqual(negativeVelocity.magnitude, 5.0), "Magnitude should be positive despite negative components")
    }

    @Test("Velocity handles very small values")
    func testVerySmallValues() async throws {
        let tinyVelocity = Velocity(dx: 0.001, dy: 0.001)

        #expect(tinyVelocity.magnitude > 0, "Tiny velocity should have positive magnitude")
        #expect(tinyVelocity.isStationary, "Tiny velocity should be considered stationary")
    }

    @Test("Velocity handles very large values")
    func testVeryLargeValues() async throws {
        let hugeVelocity = Velocity(dx: 1000.0, dy: 2000.0)

        #expect(hugeVelocity.magnitude > 0, "Large velocity should have positive magnitude")
        #expect(!hugeVelocity.isStationary, "Large velocity should not be stationary")
        #expect(hugeVelocity.magnitude > CGFloat(Constants.Physics.maxShotVelocity), "Large velocity can exceed max shot velocity")
    }

    @Test("Velocity validates against maximum shot velocity")
    func testMaxShotVelocityValidation() async throws {
        let maxVelocity = Velocity(dx: CGFloat(Constants.Physics.maxShotVelocity), dy: 0)
        let excessiveVelocity = Velocity(dx: CGFloat(Constants.Physics.maxShotVelocity) + 1, dy: 0)

        #expect(TestAssertions.assertVelocityWithinBounds(maxVelocity), "Max velocity should be within bounds")
        #expect(!TestAssertions.assertVelocityWithinBounds(excessiveVelocity), "Excessive velocity should exceed bounds")
    }

    @Test("Velocity direction calculation")
    func testVelocityDirection() async throws {
        let rightVelocity = Velocity(dx: 5.0, dy: 0)
        let upVelocity = Velocity(dx: 0, dy: 5.0)
        let diagonalVelocity = Velocity(dx: 1.0, dy: 1.0)

        let rightAngle = atan2(rightVelocity.dy, rightVelocity.dx)
        let upAngle = atan2(upVelocity.dy, upVelocity.dx)
        let diagonalAngle = atan2(diagonalVelocity.dy, diagonalVelocity.dx)

        #expect(TestAssertions.assertCGFloatEqual(rightAngle, 0), "Right velocity should have 0 angle")
        #expect(TestAssertions.assertCGFloatEqual(upAngle, CGFloat.pi / 2), "Up velocity should have π/2 angle")
        #expect(TestAssertions.assertCGFloatEqual(diagonalAngle, CGFloat.pi / 4), "Diagonal velocity should have π/4 angle")
    }

    @Test("Velocity addition and subtraction")
    func testVelocityArithmetic() async throws {
        let velocity1 = Velocity(dx: 3.0, dy: 4.0)
        let velocity2 = Velocity(dx: 1.0, dy: 2.0)

        // Note: These operations would need to be implemented in the Velocity struct
        // For now, we'll test the concept using manual calculations
        let addedDx = velocity1.dx + velocity2.dx
        let addedDy = velocity1.dy + velocity2.dy
        let addedVelocity = Velocity(dx: addedDx, dy: addedDy)

        let subtractedDx = velocity1.dx - velocity2.dx
        let subtractedDy = velocity1.dy - velocity2.dy
        let subtractedVelocity = Velocity(dx: subtractedDx, dy: subtractedDy)

        #expect(addedVelocity.dx == 4.0, "Added velocity X should be sum of components")
        #expect(addedVelocity.dy == 6.0, "Added velocity Y should be sum of components")
        #expect(subtractedVelocity.dx == 2.0, "Subtracted velocity X should be difference of components")
        #expect(subtractedVelocity.dy == 2.0, "Subtracted velocity Y should be difference of components")
    }

    @Test("Velocity scaling")
    func testVelocityScaling() async throws {
        let velocity = Velocity(dx: 2.0, dy: 4.0)
        let scale: CGFloat = 0.5

        let scaledDx = velocity.dx * scale
        let scaledDy = velocity.dy * scale
        let scaledVelocity = Velocity(dx: scaledDx, dy: scaledDy)

        #expect(scaledVelocity.dx == 1.0, "Scaled velocity X should be half original")
        #expect(scaledVelocity.dy == 2.0, "Scaled velocity Y should be half original")
        #expect(TestAssertions.assertCGFloatEqual(scaledVelocity.magnitude, velocity.magnitude * scale),
                "Scaled velocity magnitude should be proportional")
    }

    @Test("Velocity unit vector calculation")
    func testUnitVectorCalculation() async throws {
        let velocity = Velocity(dx: 6.0, dy: 8.0) // Magnitude = 10

        let unitDx = velocity.dx / velocity.magnitude
        let unitDy = velocity.dy / velocity.magnitude
        let unitVelocity = Velocity(dx: unitDx, dy: unitDy)

        #expect(TestAssertions.assertCGFloatEqual(unitVelocity.magnitude, 1.0), "Unit velocity should have magnitude 1")
        #expect(TestAssertions.assertCGFloatEqual(unitVelocity.dx, 0.6), "Unit velocity X should be normalized")
        #expect(TestAssertions.assertCGFloatEqual(unitVelocity.dy, 0.8), "Unit velocity Y should be normalized")
    }

    @Test("Velocity performance with many calculations")
    func testVelocityPerformance() async throws {
        let iterations = 10000
        let testVelocity = Velocity(dx: 3.0, dy: 4.0)

        let (_, elapsed) = PerformanceTestUtilities.measureExecutionTime {
            var total: CGFloat = 0
            for _ in 0..<iterations {
                total += testVelocity.magnitude
            }
            return total
        }

        #expect(elapsed < 0.1, "10000 magnitude calculations should complete in under 0.1 seconds")
    }
}