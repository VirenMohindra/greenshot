//
//  ScoreTests.swift
//  GreenShotTests
//
//  Unit tests for Score value object
//

import Testing
import Foundation
@testable import runner

struct ScoreTests {

    @Test("Score initializes correctly with strokes and par")
    func testScoreInitialization() async throws {
        let score = Score(strokes: 4, par: 4)

        #expect(score.strokes == 4, "Strokes should be set correctly")
        #expect(score.par == 4, "Par should be set correctly")
    }

    @Test("Score calculates relative to par correctly")
    func testRelativeToPar() async throws {
        let eagleScore = Score(strokes: 3, par: 5)    // -2
        let birdieScore = Score(strokes: 3, par: 4)   // -1
        let parScore = Score(strokes: 4, par: 4)      //  0
        let bogeyScore = Score(strokes: 5, par: 4)    // +1
        let doubleBogeyScore = Score(strokes: 6, par: 4) // +2

        #expect(eagleScore.relativeToPar == -2, "Eagle should be -2 relative to par")
        #expect(birdieScore.relativeToPar == -1, "Birdie should be -1 relative to par")
        #expect(parScore.relativeToPar == 0, "Par should be 0 relative to par")
        #expect(bogeyScore.relativeToPar == 1, "Bogey should be +1 relative to par")
        #expect(doubleBogeyScore.relativeToPar == 2, "Double bogey should be +2 relative to par")
    }

    @Test("Score identifies eagle correctly")
    func testEagleIdentification() async throws {
        let eagle = Score(strokes: 3, par: 5)
        let notEagle = Score(strokes: 3, par: 4)

        #expect(eagle.isEagle, "3 strokes on par 5 should be Eagle")
        #expect(!notEagle.isEagle, "3 strokes on par 4 should not be Eagle")
    }

    @Test("Score identifies birdie correctly")
    func testBirdieIdentification() async throws {
        let birdie = Score(strokes: 3, par: 4)
        let notBirdie = Score(strokes: 4, par: 4)

        #expect(birdie.isBirdie, "3 strokes on par 4 should be Birdie")
        #expect(!notBirdie.isBirdie, "4 strokes on par 4 should not be Birdie")
    }

    @Test("Score identifies par correctly")
    func testParIdentification() async throws {
        let par3 = Score(strokes: 3, par: 3)
        let par4 = Score(strokes: 4, par: 4)
        let par5 = Score(strokes: 5, par: 5)
        let notPar = Score(strokes: 3, par: 4)

        #expect(par3.isPar, "3 strokes on par 3 should be Par")
        #expect(par4.isPar, "4 strokes on par 4 should be Par")
        #expect(par5.isPar, "5 strokes on par 5 should be Par")
        #expect(!notPar.isPar, "3 strokes on par 4 should not be Par")
    }

    @Test("Score identifies bogey correctly")
    func testBogeyIdentification() async throws {
        let bogey = Score(strokes: 5, par: 4)
        let notBogey = Score(strokes: 4, par: 4)

        #expect(bogey.isBogey, "5 strokes on par 4 should be Bogey")
        #expect(!notBogey.isBogey, "4 strokes on par 4 should not be Bogey")
    }

    @Test("Score identifies double bogey correctly")
    func testDoubleBogeyIdentification() async throws {
        let doubleBogey = Score(strokes: 6, par: 4)
        let notDoubleBogey = Score(strokes: 5, par: 4)

        #expect(doubleBogey.isDoubleBogey, "6 strokes on par 4 should be Double Bogey")
        #expect(!notDoubleBogey.isDoubleBogey, "5 strokes on par 4 should not be Double Bogey")
    }

    @Test("Score provides correct celebration text for eagle")
    func testEagleCelebrationText() async throws {
        let eagle = Score(strokes: 3, par: 5)

        #expect(eagle.celebrationText.contains("Eagle"), "Eagle score should have Eagle in celebration text")
        #expect(eagle.celebrationText.contains("!"), "Eagle celebration should be enthusiastic")
    }

    @Test("Score provides correct celebration text for birdie")
    func testBirdieCelebrationText() async throws {
        let birdie = Score(strokes: 3, par: 4)

        #expect(birdie.celebrationText.contains("Birdie"), "Birdie score should have Birdie in celebration text")
    }

    @Test("Score provides correct celebration text for par")
    func testParCelebrationText() async throws {
        let par = Score(strokes: 4, par: 4)

        #expect(par.celebrationText.contains("Par"), "Par score should have Par in celebration text")
    }

    @Test("Score provides correct celebration text for bogey")
    func testBogeyCelebrationText() async throws {
        let bogey = Score(strokes: 5, par: 4)

        #expect(bogey.celebrationText.contains("Bogey"), "Bogey score should have Bogey in celebration text")
    }

    @Test("Score provides correct celebration text for double bogey")
    func testDoubleBogeyCelebrationText() async throws {
        let doubleBogey = Score(strokes: 6, par: 4)

        #expect(doubleBogey.celebrationText.contains("Double Bogey"), "Double Bogey score should have Double Bogey in celebration text")
    }

    @Test("Score handles extreme under par scenarios")
    func testExtremeUnderPar() async throws {
        let albatross = Score(strokes: 2, par: 5)  // -3 (very rare)
        let holeInOne = Score(strokes: 1, par: 3)  // -2 on par 3

        #expect(albatross.relativeToPar == -3, "Albatross should be -3 relative to par")
        #expect(holeInOne.relativeToPar == -2, "Hole-in-one on par 3 should be -2 relative to par")
        #expect(albatross.isEagle, "Albatross should be classified as Eagle (best available)")
        #expect(holeInOne.isEagle, "Hole-in-one should be classified as Eagle")
    }

    @Test("Score handles extreme over par scenarios")
    func testExtremeOverPar() async throws {
        let tripleBogey = Score(strokes: 7, par: 4)  // +3
        let quadrupleBogey = Score(strokes: 8, par: 4)  // +4

        #expect(tripleBogey.relativeToPar == 3, "Triple bogey should be +3 relative to par")
        #expect(quadrupleBogey.relativeToPar == 4, "Quadruple bogey should be +4 relative to par")
        #expect(tripleBogey.isDoubleBogey, "Triple bogey should be classified as Double Bogey (worst tracked)")
        #expect(quadrupleBogey.isDoubleBogey, "Quadruple bogey should be classified as Double Bogey")
    }

    @Test("Score supports Equatable protocol")
    func testEquatable() async throws {
        let score1 = Score(strokes: 4, par: 4)
        let score2 = Score(strokes: 4, par: 4)
        let score3 = Score(strokes: 5, par: 4)

        #expect(score1 == score2, "Identical scores should be equal")
        #expect(score1 != score3, "Different scores should not be equal")
    }

    @Test("Score validates input ranges")
    func testInputValidation() async throws {
        // Test minimum valid values
        let minScore = Score(strokes: 1, par: 3)
        #expect(minScore.strokes == 1, "Minimum strokes should be valid")
        #expect(minScore.par == 3, "Minimum par should be valid")

        // Test reasonable maximum values
        let maxScore = Score(strokes: 15, par: 5)
        #expect(maxScore.strokes == 15, "High stroke count should be valid")
        #expect(maxScore.par == 5, "Maximum typical par should be valid")
    }

    @Test("Score calculates percentile performance")
    func testPercentilePerformance() async throws {
        // Test what percentile various scores represent
        let excellentScore = Score(strokes: 3, par: 5)  // Eagle
        let goodScore = Score(strokes: 3, par: 4)       // Birdie
        let averageScore = Score(strokes: 4, par: 4)    // Par
        let poorScore = Score(strokes: 6, par: 4)       // Double Bogey

        // Eagles are rare (top 1% of shots for most golfers)
        #expect(excellentScore.isEagle, "Eagle should be excellent performance")

        // Birdies are good (top 10-20% for average golfers)
        #expect(goodScore.isBirdie, "Birdie should be good performance")

        // Par is average target performance
        #expect(averageScore.isPar, "Par should be target performance")

        // Double bogey and worse is poor performance
        #expect(poorScore.isDoubleBogey, "Double bogey should be poor performance")
    }

    @Test("Score handles edge case: zero strokes")
    func testZeroStrokesEdgeCase() async throws {
        // This shouldn't happen in normal gameplay, but test robustness
        let impossibleScore = Score(strokes: 0, par: 4)

        #expect(impossibleScore.strokes == 0, "Zero strokes should be stored")
        #expect(impossibleScore.relativeToPar == -4, "Zero strokes should be -4 on par 4")
        #expect(impossibleScore.isEagle, "Zero strokes should be classified as Eagle")
    }

    @Test("Score performance with many calculations")
    func testScorePerformance() async throws {
        let iterations = 1000
        let scores = (1...iterations).map { Score(strokes: $0 % 7 + 1, par: 4) }

        let (_, elapsed) = PerformanceTestUtilities.measureExecutionTime {
            var eagleCount = 0
            var birdieCount = 0
            var parCount = 0

            for score in scores {
                if score.isEagle { eagleCount += 1 }
                else if score.isBirdie { birdieCount += 1 }
                else if score.isPar { parCount += 1 }
            }

            return (eagleCount, birdieCount, parCount)
        }

        #expect(elapsed < 0.01, "1000 score classifications should complete in under 0.01 seconds")
    }

    @Test("Score text formatting consistency")
    func testTextFormattingConsistency() async throws {
        let scores = [
            Score(strokes: 3, par: 5),  // Eagle
            Score(strokes: 3, par: 4),  // Birdie
            Score(strokes: 4, par: 4),  // Par
            Score(strokes: 5, par: 4),  // Bogey
            Score(strokes: 6, par: 4)   // Double Bogey
        ]

        for score in scores {
            let text = score.celebrationText

            #expect(!text.isEmpty, "Celebration text should not be empty")
            #expect(text.count > 2, "Celebration text should be meaningful")

            // Check that text matches score type
            if score.isEagle {
                #expect(text.lowercased().contains("eagle"), "Eagle text should contain 'eagle'")
            } else if score.isBirdie {
                #expect(text.lowercased().contains("birdie"), "Birdie text should contain 'birdie'")
            } else if score.isPar {
                #expect(text.lowercased().contains("par"), "Par text should contain 'par'")
            } else if score.isBogey {
                #expect(text.lowercased().contains("bogey"), "Bogey text should contain 'bogey'")
            }
        }
    }
}