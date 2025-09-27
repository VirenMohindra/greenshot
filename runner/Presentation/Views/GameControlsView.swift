//
//  GameControlsView.swift
//  runner
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
                    score: viewModel.currentScore
                )

                Spacer()

                LeaderboardButton {
                    viewModel.openLeaderboard()
                }

                DebugButton {
                    viewModel.openHoleDebug()
                }
            }
            .padding(.horizontal, 20) // Add horizontal padding
            .padding(.top, 10)

            Spacer()

            // Bottom controls (if needed)
            if viewModel.isPaused {
                PauseOverlay {
                    viewModel.resumeGame()
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

struct LeaderboardButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "trophy.fill")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundColor(.goldenYellow)
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

struct DebugButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: "eye.fill")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundColor(.cyan)
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
        holeGenerationService: HoleGenerationService(scoringService: ScoringService())
    )

    let viewModel = GameViewModel(gameController: gameController)

    GameControlsView(viewModel: viewModel)
        .background(Color.green.ignoresSafeArea())
}