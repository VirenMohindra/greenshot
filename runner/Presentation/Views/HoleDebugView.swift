//
//  HoleDebugView.swift
//  runner
//
//  Debug view to visualize all generated holes in a course
//

import SwiftUI

struct HoleDebugView: View {
    let course: Course
    @State private var selectedHole: Int = 1

    var body: some View {
        VStack(spacing: 20) {
            Text("Course: \(course.name)")
                .font(.title2)
                .fontWeight(.bold)

            Text("Generated with \(course.holes.count) holes")
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Hole selector
            Picker("Hole", selection: $selectedHole) {
                ForEach(course.holes, id: \.number) { hole in
                    Text("Hole \(hole.number)").tag(hole.number)
                }
            }
            .pickerStyle(SegmentedPickerStyle())

            if let hole = course.holes.first(where: { $0.number == selectedHole }) {
                HoleVisualization(hole: hole)
            }

            Spacer()
        }
        .padding()
    }
}

struct HoleVisualization: View {
    let hole: Hole

    private var scale: CGFloat { 0.3 }
    private var holeWidth: CGFloat { 300 }
    private var holeHeight: CGFloat { 400 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Hole info
            HStack {
                VStack(alignment: .leading) {
                    Text("Hole \(hole.number)")
                        .font(.title3)
                        .fontWeight(.semibold)

                    Text("Par \(hole.par)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)

                    Text("\(hole.difficulty.displayName)")
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(difficultyColor(hole.difficulty))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text("Distance: \(Int(hole.teePosition.distance(to: hole.pinPosition))) yds")
                        .font(.caption)

                    Text("Obstacles: \(hole.obstacles.count)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Trees: \(hole.obstacles.filter { $0.type == .tree }.count)")
                        .font(.caption)
                        .foregroundColor(.green)
                }
            }

            // Course visualization
            ZStack {
                Rectangle()
                    .fill(Color.green.opacity(0.3))
                    .frame(width: holeWidth, height: holeHeight)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray, lineWidth: 1)
                    )

                // Fairway path
                FairwayPathView(path: hole.fairwayPath, scale: scale)

                // Obstacles
                ForEach(Array(hole.obstacles.enumerated()), id: \.offset) { index, obstacle in
                    ObstacleView(obstacle: obstacle, scale: scale)
                }

                // Tee position
                Circle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 12)
                    .position(
                        x: hole.teePosition.x * scale,
                        y: holeHeight - (hole.teePosition.y * scale)
                    )
                    .overlay(
                        Text("T")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .position(
                                x: hole.teePosition.x * scale,
                                y: holeHeight - (hole.teePosition.y * scale)
                            )
                    )

                // Pin position
                Circle()
                    .fill(Color.red)
                    .frame(width: 12, height: 12)
                    .position(
                        x: hole.pinPosition.x * scale,
                        y: holeHeight - (hole.pinPosition.y * scale)
                    )
                    .overlay(
                        Text("P")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .position(
                                x: hole.pinPosition.x * scale,
                                y: holeHeight - (hole.pinPosition.y * scale)
                            )
                    )
            }
            .frame(width: holeWidth, height: holeHeight)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 8, height: 8)
                    Text("Tee").font(.caption2)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.red).frame(width: 8, height: 8)
                    Text("Pin").font(.caption2)
                }
                HStack(spacing: 4) {
                    Circle().fill(Color.brown).frame(width: 8, height: 8)
                    Text("Tree").font(.caption2)
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.blue.opacity(0.7)).frame(width: 8, height: 8)
                    Text("Water").font(.caption2)
                }
                HStack(spacing: 4) {
                    Rectangle().fill(Color.yellow.opacity(0.7)).frame(width: 8, height: 8)
                    Text("Bunker").font(.caption2)
                }
            }
            .font(.caption2)
        }
        .padding()
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func difficultyColor(_ difficulty: Difficulty) -> Color {
        switch difficulty.level {
        case 0.0..<0.3: return .green
        case 0.3..<0.7: return .orange
        default: return .red
        }
    }
}

struct FairwayPathView: View {
    let path: CGPath
    let scale: CGFloat

    var body: some View {
        Path { uiPath in
            var transform = CGAffineTransform(scaleX: scale, y: -scale)
            let scaledPath = path.copy(using: &transform)
            if let scaledPath = scaledPath {
                uiPath.addPath(Path(scaledPath))
            }
        }
        .fill(Color.green.opacity(0.6))
        .stroke(Color.green.opacity(0.8), lineWidth: 1)
    }
}

struct ObstacleView: View {
    let obstacle: Obstacle
    let scale: CGFloat

    var body: some View {
        Group {
            switch obstacle.type {
            case .tree:
                Circle()
                    .fill(Color.brown)
                    .frame(
                        width: obstacle.size.width * scale,
                        height: obstacle.size.height * scale
                    )

            case .water:
                Rectangle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(
                        width: obstacle.size.width * scale,
                        height: obstacle.size.height * scale
                    )

            case .bunker:
                Rectangle()
                    .fill(Color.yellow.opacity(0.7))
                    .frame(
                        width: obstacle.size.width * scale,
                        height: obstacle.size.height * scale
                    )

            case .rough:
                Rectangle()
                    .fill(Color.green.opacity(0.5))
                    .frame(
                        width: obstacle.size.width * scale,
                        height: obstacle.size.height * scale
                    )
            }
        }
        .position(
            x: obstacle.position.x * scale,
            y: 400 - (obstacle.position.y * scale) // Flip Y coordinate
        )
    }
}

#Preview {
    let mockDifficulty = Difficulty(0.5)
    let mockHole = Hole(
        number: 1,
        par: 4,
        difficulty: mockDifficulty,
        teePosition: Position(x: 400, y: 100),
        pinPosition: Position(x: 400, y: 500),
        fairwayPath: CGPath(rect: CGRect(x: 350, y: 100, width: 100, height: 400), transform: nil),
        obstacles: [
            Obstacle(type: .tree, position: Position(x: 300, y: 250), size: CGSize(width: 20, height: 20)),
            Obstacle(type: .water, position: Position(x: 500, y: 300), size: CGSize(width: 60, height: 40))
        ]
    )
    let mockCourse = Course(name: "Test Course", holes: [mockHole], worldSize: CGSize(width: 800, height: 600))

    HoleDebugView(course: mockCourse)
}