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

    var body: some View {
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

            // Score Section
            ScoreboardSection(
                title: "SCORE",
                value: scoreDisplay,
                color: scoreColor
            )
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
        guard let score = score else { return "-" }
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
            score: Score(strokes: 3, par: 4)
        )

        ScoreboardView(
            hole: 2,
            par: 3,
            strokes: 2,
            score: Score(strokes: 2, par: 3)
        )

        ScoreboardView(
            hole: 3,
            par: 5,
            strokes: 6,
            score: Score(strokes: 6, par: 5)
        )
    }
    .padding()
    .background(Color.blue.ignoresSafeArea())
}
