//
//  GameControlsView.swift
//  GreenShot
//
//  Game UI controls and overlays
//

import SwiftUI

extension Color {
    static let goldenYellow = Color(red: 1.0, green: 0.8, blue: 0.0)
    static let golfGreen = Color(red: 0.13, green: 0.37, blue: 0.15)
}

struct GameControlsView: View {
    @ObservedObject var viewModel: GameViewModel
    @Binding var showCourseOverview: Bool

    var body: some View {
        VStack {
            // Top controls
            HStack {
                MenuButton {
                    viewModel.openSettings()
                }

                Spacer()

                ScoreboardView(
                    hole: viewModel.currentHole,
                    par: viewModel.currentPar,
                    strokes: viewModel.currentStrokes,
                    score: viewModel.currentScore,
                    totalScore: viewModel.totalScore,
                    roundProgress: viewModel.roundProgressText
                )

                Spacer()

                VStack(spacing: Constants.UI.buttonSpacing) {
                    CourseOverviewButton {
                        showCourseOverview = true
                    }

                    LeaderboardButton {
                        viewModel.openLeaderboard()
                    }

                    GameCenterButton {
                        viewModel.openGameCenter()
                    }

                    DebugButton {
                        viewModel.openHoleDebug()
                    }
                }
            }
            .padding(.horizontal, Constants.UI.Padding.large)
            .padding(.top, Constants.UI.Padding.small)

            Spacer()

            // Bottom controls (if needed)
            if viewModel.isPaused {
                PauseOverlay {
                    viewModel.resumeGame()
                }
            }

            // Celebration overlay
            if viewModel.isCelebrationVisible {
                CelebrationOverlay(
                    text: viewModel.celebrationText,
                    level: viewModel.celebrationLevel
                ) {
                    viewModel.hideCelebration()
                }
            }

            // Hole progression overlay
            if viewModel.showHoleProgressionMessage {
                HoleProgressionOverlay(
                    text: viewModel.holeProgressionText
                ) {
                    viewModel.hideHoleProgression()
                }
            }
        }
    }
}

struct MenuButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "line.horizontal.3")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 44, height: 44)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.7))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 1)
                        )
                )
                .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
    }
}

struct CourseOverviewButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "map.fill")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
                .frame(width: Constants.UI.buttonSize, height: Constants.UI.buttonSize)
                .background(
                    Circle()
                        .fill(Color.black.opacity(Constants.Colors.UI.buttonBackgroundAlpha))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(Constants.Colors.UI.buttonBorderAlpha), lineWidth: Constants.UI.borderWidth)
                        )
                )
                .shadow(color: .black.opacity(Constants.Colors.UI.shadowOpacityAlpha), radius: Constants.UI.shadowRadius, x: 0, y: 2)
        }
    }
}

struct LeaderboardButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.goldenYellow)
                .frame(width: Constants.UI.buttonSize, height: Constants.UI.buttonSize)
                .background(
                    Circle()
                        .fill(Color.black.opacity(Constants.Colors.UI.buttonBackgroundAlpha))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(Constants.Colors.UI.buttonBorderAlpha), lineWidth: Constants.UI.borderWidth)
                        )
                )
                .shadow(color: .black.opacity(Constants.Colors.UI.shadowOpacityAlpha), radius: Constants.UI.shadowRadius, x: 0, y: 2)
        }
    }
}

struct GameCenterButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "gamecontroller.fill")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(.orange)
                .frame(width: Constants.UI.buttonSize, height: Constants.UI.buttonSize)
                .background(
                    Circle()
                        .fill(Color.black.opacity(Constants.Colors.UI.buttonBackgroundAlpha))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(Constants.Colors.UI.buttonBorderAlpha), lineWidth: Constants.UI.borderWidth)
                        )
                )
                .shadow(color: .black.opacity(Constants.Colors.UI.shadowOpacityAlpha), radius: Constants.UI.shadowRadius, x: 0, y: 2)
        }
    }
}

struct DebugButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "eye.fill")
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
                .frame(width: Constants.UI.buttonSize, height: Constants.UI.buttonSize)
                .background(
                    Circle()
                        .fill(Color.black.opacity(Constants.Colors.UI.buttonBackgroundAlpha))
                        .overlay(
                            Circle()
                                .stroke(Color.white.opacity(Constants.Colors.UI.buttonBorderAlpha), lineWidth: Constants.UI.borderWidth)
                        )
                )
                .shadow(color: .black.opacity(Constants.Colors.UI.shadowOpacityAlpha), radius: Constants.UI.shadowRadius, x: 0, y: 2)
        }
    }
}

struct PauseOverlay: View {
    let resumeAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("GAME PAUSED")
                .font(.system(size: 28, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(.white)

            Button("RESUME PLAY") {
                resumeAction()
            }
            .font(.system(size: 16, weight: .bold, design: .rounded))
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(Color.golfGreen)
            .foregroundColor(.white)
            .cornerRadius(25)
            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.black.opacity(0.9))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    let gameController = GameController(
        takeShotUseCase: TakeShotUseCase(physicsService: PhysicsService()),
        completeHoleUseCase: CompleteHoleUseCase(scoringService: ScoringService()),
        navigateHolesUseCase: NavigateHolesUseCase(),
        updateCameraUseCase: UpdateCameraUseCase(),
        holeGenerationService: HoleGenerationService(scoringService: ScoringService()),
        gameCenterService: MockGameCenterService(),
        persistenceService: MockPersistenceService(),
        eventBus: EventBus()
    )

    let viewModel = GameViewModel(gameController: gameController)

    GameControlsView(viewModel: viewModel, showCourseOverview: .constant(false))
        .background(Color.green.ignoresSafeArea())
}

struct CelebrationOverlay: View {
    let text: String
    let level: CelebrationLevel
    let dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            // Celebration icon
            Image(systemName: celebrationIcon)
                .font(.system(size: 60, weight: .bold, design: .rounded))
                .foregroundColor(celebrationColor)
                .scaleEffect(1.2)
                .animation(.easeInOut(duration: 0.6).repeatCount(3, autoreverses: true), value: level)

            // Celebration text
            Text(text)
                .font(.system(size: 28, weight: .black, design: .rounded))
                .tracking(2)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)

            // Tap to dismiss hint (for longer celebrations)
            if level.duration > 2.0 {
                Text("Tap to continue")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.top, 10)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 25)
                .fill(celebrationBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 25)
                        .stroke(celebrationColor.opacity(0.8), lineWidth: 3)
                )
        )
        .shadow(color: .black.opacity(0.5), radius: 15, x: 0, y: 8)
        .scaleEffect(1.1)
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: level)
        .onTapGesture {
            dismissAction()
        }
    }

    private var celebrationIcon: String {
        switch level {
        case .none: return "checkmark.circle"
        case .minor: return "hand.thumbsup.fill"
        case .moderate: return "star.fill"
        case .major: return "crown.fill"
        case .spectacular: return "trophy.fill"
        }
    }

    private var celebrationColor: Color {
        switch level {
        case .none: return .white
        case .minor: return .cyan
        case .moderate: return .yellow
        case .major: return .orange
        case .spectacular: return .goldenYellow
        }
    }

    private var celebrationBackgroundColor: Color {
        switch level {
        case .none: return Color.black.opacity(0.8)
        case .minor: return Color.blue.opacity(0.9)
        case .moderate: return Color.purple.opacity(0.9)
        case .major: return Color.red.opacity(0.9)
        case .spectacular: return Color.black.opacity(0.95)
        }
    }
}

struct HoleProgressionOverlay: View {
    let text: String
    let dismissAction: () -> Void

    var body: some View {
        HStack(spacing: 15) {
            Image(systemName: "arrow.right.circle.fill")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.goldenYellow)

            Text(text)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Capsule()
                .fill(Color.black.opacity(0.85))
                .overlay(
                    Capsule()
                        .stroke(Color.goldenYellow.opacity(0.6), lineWidth: 2)
                )
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
        .transition(.scale.combined(with: .opacity))
        .onTapGesture {
            dismissAction()
        }
    }
}