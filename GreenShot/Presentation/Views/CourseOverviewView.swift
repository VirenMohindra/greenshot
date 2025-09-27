//
//  CourseOverviewView.swift
//  GreenShot
//
//  Shows overview of all holes in the golf course
//

import SwiftUI

struct CourseOverviewView: View {
    let holes: [Hole]
    let currentHoleIndex: Int
    @Binding var isPresented: Bool

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Course Stats
                    CourseStatsView(holes: holes)
                        .padding(.horizontal)

                    // Holes Grid
                    LazyVGrid(columns: columns, spacing: 15) {
                        ForEach(Array(holes.enumerated()), id: \.element.id) { index, hole in
                            HoleCardView(
                                hole: hole,
                                holeNumber: index + 1,
                                isCurrentHole: index == currentHoleIndex
                            )
                        }
                    }
                    .padding()
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Course Overview")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        isPresented = false
                    }
                }
            }
        }
    }
}

struct CourseStatsView: View {
    let holes: [Hole]

    var totalPar: Int {
        holes.reduce(0) { $0 + $1.par }
    }

    var totalDistance: Int {
        holes.reduce(0) { $0 + Int($1.distance) }
    }

    var averageDifficulty: Double {
        let total = holes.reduce(0.0) { $0 + Double($1.difficulty.level) }
        return total / Double(max(holes.count, 1))
    }

    var body: some View {
        HStack(spacing: 20) {
            StatCard(title: "Total Par", value: "\(totalPar)", icon: "flag.fill")
            StatCard(title: "Distance", value: "\(totalDistance) yds", icon: "location.fill")
            StatCard(title: "Difficulty", value: String(format: "%.1f", averageDifficulty), icon: "star.fill")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.accentColor)

            Text(value)
                .font(.headline)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }
}

struct HoleCardView: View {
    let hole: Hole
    let holeNumber: Int
    let isCurrentHole: Bool

    var parColor: Color {
        switch hole.par {
        case 3: return .blue
        case 4: return .green
        case 5: return .orange
        default: return .gray
        }
    }

    var difficultyEmoji: String {
        switch hole.difficulty.level {
        case ..<0.3: return "😊"
        case 0.3..<0.7: return "😐"
        default: return "😤"
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Hole Number
            ZStack {
                Circle()
                    .fill(isCurrentHole ? Color.accentColor : Color(UIColor.tertiarySystemFill))
                    .frame(width: 40, height: 40)

                Text("\(holeNumber)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(isCurrentHole ? .white : .primary)
            }

            // Par Badge
            HStack(spacing: 4) {
                Image(systemName: "flag.fill")
                    .font(.caption)
                Text("Par \(hole.par)")
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .foregroundColor(parColor)

            // Distance
            Text("\(Int(hole.distance)) yds")
                .font(.footnote)
                .foregroundColor(.secondary)

            // Difficulty
            Text(difficultyEmoji)
                .font(.title2)

            // Obstacle count
            if hole.obstacles.count > 0 {
                HStack(spacing: 2) {
                    Image(systemName: "tree.fill")
                        .font(.caption2)
                    Text("\(hole.obstacles.count)")
                        .font(.caption2)
                }
                .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isCurrentHole ?
                    Color.accentColor.opacity(0.1) :
                    Color(UIColor.secondarySystemGroupedBackground))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isCurrentHole ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }
}

// Preview
struct CourseOverviewView_Previews: PreviewProvider {
    static var previews: some View {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: 385, y: 0))

        return CourseOverviewView(
            holes: [
                Hole(number: 1, par: 4, difficulty: Difficulty(0.5),
                     teePosition: Position(x: 0, y: 0),
                     pinPosition: Position(x: 385, y: 0),
                     fairwayPath: path, obstacles: []),
                Hole(number: 2, par: 3, difficulty: Difficulty(0.3),
                     teePosition: Position(x: 0, y: 0),
                     pinPosition: Position(x: 165, y: 0),
                     fairwayPath: path, obstacles: []),
                Hole(number: 3, par: 5, difficulty: Difficulty(0.7),
                     teePosition: Position(x: 0, y: 0),
                     pinPosition: Position(x: 520, y: 0),
                     fairwayPath: path, obstacles: [])
            ],
            currentHoleIndex: 0,
            isPresented: .constant(true)
        )
    }
}