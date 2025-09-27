//
//  Score.swift
//  GreenShot
//
//  Golf scoring value object with par calculations
//

import Foundation

struct Score: Equatable, Hashable {
    let strokes: Int
    let par: Int

    init(strokes: Int, par: Int) {
        self.strokes = strokes
        self.par = par
    }
}

// MARK: - Score Calculations
extension Score {
    var relativeToPar: Int {
        strokes - par
    }

    var isHoleInOne: Bool {
        strokes == 1
    }

    var isAlbatross: Bool {
        relativeToPar <= -3
    }

    var isEagle: Bool {
        relativeToPar == -2
    }

    var isBirdie: Bool {
        relativeToPar == -1
    }

    var isPar: Bool {
        relativeToPar == 0
    }

    var isBogey: Bool {
        relativeToPar == 1
    }

    var isDoubleBogey: Bool {
        relativeToPar == 2
    }
}

// MARK: - Display Properties
extension Score {
    var displayText: String {
        switch relativeToPar {
        case ...(-3): return "ALB"
        case -2: return "EAG"
        case -1: return "BIR"
        case 0: return "PAR"
        case 1: return "BOG"
        case 2: return "+2"
        default: return "+\(relativeToPar)"
        }
    }

    var celebrationText: String {
        if isHoleInOne {
            return "Hole in One!"
        }

        switch relativeToPar {
        case ...(-3): return "Albatross!"
        case -2: return "Eagle!"
        case -1: return "Birdie!"
        case 0: return "Par!"
        case 1: return "Bogey"
        case 2: return "Double Bogey"
        default: return "+\(relativeToPar)"
        }
    }
}

// MARK: - Score Quality
enum ScoreQuality {
    case excellent  // Eagle or better
    case good       // Birdie
    case average    // Par
    case poor       // Bogey
    case terrible   // Double bogey or worse
}

extension Score {
    var quality: ScoreQuality {
        switch relativeToPar {
        case ...(-2): return .excellent
        case -1: return .good
        case 0: return .average
        case 1: return .poor
        default: return .terrible
        }
    }
}