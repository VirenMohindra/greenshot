//
//  HoleDebugView.swift
//  runner
//
//  Debug view to visualize all generated holes in a course
//

import SwiftUI

struct HoleDebugView: View {
    let course: Course
    @State private var selectedView: ViewMode = .grid
    @State private var selectedHole: Int = 1

    enum ViewMode: String, CaseIterable {
        case grid = "Grid"
        case detail = "Detail"
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header with course info
                VStack(spacing: 8) {
                    Text(course.name)
                        .font(.title2)
                        .fontWeight(.bold)

                    Text("Generated with \(course.holes.count) holes • Total Par: \(course.totalPar)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGroupedBackground))

                // View mode picker
                Picker("View Mode", selection: $selectedView) {
                    ForEach(ViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)

                // Content based on selected view
                if selectedView == .grid {
                    CourseGridView(course: course)
                } else {
                    VStack(spacing: 16) {
                        // Improved hole selector for detail view
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(course.holes, id: \.number) { hole in
                                    Button(action: { selectedHole = hole.number }) {
                                        VStack(spacing: 4) {
                                            Text("\(hole.number)")
                                                .font(.headline)
                                                .fontWeight(.bold)
                                            Text("Par \(hole.par)")
                                                .font(.caption)
                                        }
                                        .foregroundColor(selectedHole == hole.number ? .white : .primary)
                                        .frame(width: 50, height: 50)
                                        .background(
                                            Circle()
                                                .fill(selectedHole == hole.number ? Color.accentColor : Color(.systemGray5))
                                        )
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }

                        if let hole = course.holes.first(where: { $0.number == selectedHole }) {
                            ScrollView {
                                HoleVisualization(hole: hole)
                                    .padding()
                            }
                        }
                    }
                }

                Spacer(minLength: 0)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarHidden(true)
        }
    }
}

struct CourseGridView: View {
    let course: Course

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8)
    ]

    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(course.holes, id: \.number) { hole in
                    CompactHoleCard(hole: hole)
                }
            }
            .padding()
        }
    }
}

struct CompactHoleCard: View {
    let hole: Hole

    private var scale: CGFloat { 0.15 }
    private var cardSize: CGFloat { 120 }

    var parColor: Color {
        switch hole.par {
        case 3: return .blue
        case 4: return .green
        case 5: return .orange
        default: return .gray
        }
    }

    var difficultyColor: Color {
        switch hole.difficulty.level {
        case 0.0..<0.3: return .green
        case 0.3..<0.7: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Hole number and par
            HStack {
                Text("\(hole.number)")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Text("Par \(hole.par)")
                    .font(.caption)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(parColor.opacity(0.2))
                    .foregroundColor(parColor)
                    .clipShape(Capsule())
            }

            // Mini course visualization
            ZStack {
                Rectangle()
                    .fill(Color.green.opacity(0.2))
                    .frame(width: cardSize - 20, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 4))

                // Fairway path (simplified)
                Rectangle()
                    .fill(Color.green.opacity(0.4))
                    .frame(width: 40, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 2))

                // Tee
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .position(x: 20, y: 50)

                // Pin
                Circle()
                    .fill(Color.red)
                    .frame(width: 6, height: 6)
                    .position(x: cardSize - 40, y: 10)

                // Obstacles (simplified)
                ForEach(Array(hole.obstacles.prefix(3).enumerated()), id: \.offset) { index, obstacle in
                    Circle()
                        .fill(obstacleColor(obstacle.type))
                        .frame(width: 4, height: 4)
                        .position(
                            x: CGFloat(20 + index * 15),
                            y: CGFloat(25 + index * 5)
                        )
                }
            }
            .frame(width: cardSize - 20, height: 60)

            // Info row
            HStack(spacing: 4) {
                // Distance
                VStack(spacing: 2) {
                    Text("\(Int(hole.teePosition.distance(to: hole.pinPosition)))")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("yds")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Difficulty indicator
                Circle()
                    .fill(difficultyColor)
                    .frame(width: 8, height: 8)

                Spacer()

                // Obstacle count
                VStack(spacing: 2) {
                    Text("\(hole.obstacles.count)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                    Text("obs")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(8)
        .frame(width: cardSize, height: cardSize)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
    }

    private func obstacleColor(_ type: ObstacleType) -> Color {
        switch type {
        case .tree: return .brown
        case .water: return .blue
        case .bunker: return .yellow
        case .rough: return .green
        }
    }
}

struct HoleVisualization: View {
    let hole: Hole

    private var scale: CGFloat { 0.4 }
    private var holeWidth: CGFloat { 350 }
    private var holeHeight: CGFloat { 450 }

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