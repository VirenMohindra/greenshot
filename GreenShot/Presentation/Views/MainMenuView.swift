//
//  MainMenuView.swift
//  GreenShot
//
//  Main menu with navigation to game modes and settings
//

import SwiftUI

struct MainMenuView: View {
    @State private var showSettings = false
    @State private var showLeaderboard = false
    @State private var showGameCenter = false
    @State private var isButtonAnimated = false

    let onStartGame: () -> Void

    // Create dependencies using DependencyContainer for proper initialization
    private let dependencyContainer = DependencyContainer()

    private var gameCenterManager: GameCenterManager {
        dependencyContainer.gameCenterManager
    }

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.golfGreen.opacity(0.9),
                    Color.golfGreen,
                    Color.black.opacity(0.8)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 40) {
                Spacer()

                // Logo and title section
                VStack(spacing: 20) {
                    // Golf ball logo
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 100, height: 100)
                            .shadow(color: .black.opacity(0.3), radius: 8, x: 0, y: 4)

                        // Golf ball dimples
                        VStack(spacing: 6) {
                            HStack(spacing: 6) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            HStack(spacing: 6) {
                                ForEach(0..<3, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                            HStack(spacing: 6) {
                                ForEach(0..<4, id: \.self) { _ in
                                    Circle()
                                        .fill(Color.gray.opacity(0.3))
                                        .frame(width: 6, height: 6)
                                }
                            }
                        }
                    }
                    .scaleEffect(isButtonAnimated ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isButtonAnimated)

                    Text("GreenShot")
                        .font(.system(size: 42, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 2)

                    Text("Premium Golf Experience")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.goldenYellow)
                        .opacity(0.9)
                }

                Spacer()

                // Menu buttons
                VStack(spacing: 20) {
                    // Play Game button
                    Button(action: onStartGame) {
                        HStack(spacing: 12) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20, weight: .bold))

                            Text("PLAY GOLF")
                                .font(.system(size: 18, weight: .bold, design: .rounded))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [.golfGreen, .golfGreen.opacity(0.8)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(28)
                        .shadow(color: .black.opacity(0.3), radius: 6, x: 0, y: 3)
                    }
                    .scaleEffect(isButtonAnimated ? 1.02 : 1.0)
                    .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.2), value: isButtonAnimated)

                    // Game Center button
                    Button(action: { showGameCenter = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "gamecontroller.fill")
                                .font(.system(size: 18, weight: .bold))

                            Text("GAME CENTER")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.goldenYellow.opacity(0.6), lineWidth: 2)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }

                    // Leaderboard button
                    Button(action: { showLeaderboard = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 18, weight: .bold))

                            Text("LEADERBOARD")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.goldenYellow.opacity(0.6), lineWidth: 2)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }

                    // Settings button
                    Button(action: { showSettings = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "gear.circle.fill")
                                .font(.system(size: 18, weight: .bold))

                            Text("SETTINGS")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .tracking(1)
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 50)
                        .background(
                            RoundedRectangle(cornerRadius: 25)
                                .fill(Color.black.opacity(0.7))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 25)
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                )
                        )
                        .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 40)

                Spacer()

                // Version info
                Text("v1.0.0")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
            .padding(.vertical, 40)
        }
        .onAppear {
            isButtonAnimated = true
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $showLeaderboard) {
            LeaderboardView()
        }
        .sheet(isPresented: $showGameCenter) {
            GameCenterView(gameCenterManager: gameCenterManager)
        }
    }
}

#Preview {
    MainMenuView {
        print("Start game tapped")
    }
}