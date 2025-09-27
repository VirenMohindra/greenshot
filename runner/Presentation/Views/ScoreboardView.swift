//
//  ScoreboardView.swift
//  runner
//
//  Broadcast-style golf scoreboard SwiftUI view
//

import SwiftUI

struct ScoreboardView: View {
    let hole: Int
    let par: Int
    let strokes: Int
    let score: Score?
    let totalScore: Int
    let roundProgress: String

    var body: some View {
        VStack(spacing: 8) {
            // Round Progress
            Text(roundProgress)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

            HStack(spacing: 0) {
                // Hole Section
                ScoreboardSection(title: "HOLE", value: "\(hole)", color: .white)

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))

                // Par Section
                ScoreboardSection(title: "PAR", value: "\(par)", color: .yellow)

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))

                // Strokes Section
                ScoreboardSection(
                    title: "STROKE",
                    value: "\(strokes)",
                    color: strokeColor
                )

                Divider()
                    .frame(height: 40)
                    .background(Color.white.opacity(0.3))

                // Total Score Section
                ScoreboardSection(
                    title: "TOTAL",
                    value: totalScoreDisplay,
                    color: totalScoreColor
                )
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(0.8), lineWidth: 2)
                )
        )
        .shadow(radius: 10)
    }

    private var strokeColor: Color {
        guard let score = score else { return .white }

        switch score.quality {
        case .excellent: return .green
        case .good: return Color(red: 0.2, green: 0.9, blue: 0.2)
        case .average: return .white
        case .poor: return .yellow
        case .terrible: return .red
        }
    }

    private var scoreDisplay: String {
        if strokes == 0 {
            return "E"  // Even/starting score before any shots
        }
        guard let score = score else { return "\(strokes)" }
        return score.displayText
    }

    private var scoreColor: Color {
        guard let score = score else { return .white }

        switch score.quality {
        case .excellent: return .green
        case .good: return Color(red: 0.2, green: 0.9, blue: 0.2)
        case .average: return .white
        case .poor: return .yellow
        case .terrible: return Color(red: 1.0, green: 0.4, blue: 0.4)
        }
    }

    private var totalScoreDisplay: String {
        if totalScore == 0 {
            return "E"  // Even par
        } else if totalScore > 0 {
            return "+\(totalScore)"  // Over par
        } else {
            return "\(totalScore)"  // Under par (already has negative sign)
        }
    }

    private var totalScoreColor: Color {
        if totalScore < 0 {
            return .green  // Under par (good)
        } else if totalScore == 0 {
            return .white  // Even par
        } else if totalScore <= 5 {
            return .yellow  // Slightly over par
        } else {
            return .red  // Well over par
        }
    }
}

struct ScoreboardSection: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundColor(.white.opacity(0.9))

            Text(value)
                .font(.system(size: 24, weight: .black, design: .rounded))
                .foregroundColor(color)
        }
        .frame(minWidth: 60)
    }
}

#Preview {
    VStack(spacing: 20) {
        ScoreboardView(
            hole: 1,
            par: 4,
            strokes: 3,
            score: Score(strokes: 3, par: 4),
            totalScore: -1,
            roundProgress: "1/9 Holes"
        )

        ScoreboardView(
            hole: 2,
            par: 3,
            strokes: 2,
            score: Score(strokes: 2, par: 3),
            totalScore: -2,
            roundProgress: "2/9 Holes"
        )

        ScoreboardView(
            hole: 3,
            par: 5,
            strokes: 6,
            score: Score(strokes: 6, par: 5),
            totalScore: -1,
            roundProgress: "3/9 Holes"
        )
    }
    .padding()
    .background(Color.blue.ignoresSafeArea())
}
