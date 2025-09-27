//
//  GameCenterView.swift
//  GreenShot
//
//  GameCenter integration UI with leaderboards and achievements
//

import SwiftUI
import GameKit

struct GameCenterView: View {
    @ObservedObject private var gameCenterManager: GameCenterManager
    @Environment(\.dismiss) private var dismiss

    private let gameCenterDelegate = GameCenterDelegate()

    init(gameCenterManager: GameCenterManager) {
        self.gameCenterManager = gameCenterManager
    }

    var body: some View {
        NavigationView {
            List {
                // Authentication Section
                Section("GameCenter Status") {
                    HStack {
                        Image(systemName: gameCenterManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(gameCenterManager.isAuthenticated ? .green : .red)

                        VStack(alignment: .leading) {
                            Text(gameCenterManager.isAuthenticated ? "Authenticated" : "Not Authenticated")
                                .font(.headline)

                            if let playerName = gameCenterManager.currentPlayer {
                                Text("Welcome, \(playerName)!")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("Sign in to GameCenter to track scores and achievements")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Spacer()

                        if !gameCenterManager.isAuthenticated {
                            Button("Sign In") {
                                Task {
                                    await gameCenterManager.authenticate()
                                }
                            }
                            .buttonStyle(.borderedProminent)
                        }
                    }
                }

                // Leaderboard Section
                if gameCenterManager.isAuthenticated {
                    Section("Leaderboard") {
                        if gameCenterManager.isLoadingLeaderboard {
                            HStack {
                                ProgressView()
                                    .scaleEffect(0.8)
                                Text("Loading leaderboard...")
                                    .foregroundColor(.secondary)
                            }
                        } else if gameCenterManager.leaderboardEntries.isEmpty {
                            Text("No leaderboard data available")
                                .foregroundColor(.secondary)
                                .italic()
                        } else {
                            ForEach(Array(gameCenterManager.leaderboardEntries.enumerated()), id: \.offset) { index, entry in
                                LeaderboardRowView(entry: entry, isCurrentPlayer: entry.playerName == gameCenterManager.currentPlayer)
                            }
                        }

                        Button("Refresh Leaderboard") {
                            Task {
                                await gameCenterManager.loadLeaderboard()
                            }
                        }
                        .disabled(gameCenterManager.isLoadingLeaderboard)
                    }

                    // Multiplayer Section
                    Section("Multiplayer") {
                        Button("Find 2-Player Match") {
                            gameCenterManager.findMultiplayerMatch(playerCount: 2)
                        }
                        .disabled(true) // Disabled for now until full multiplayer implementation

                        Button("Find 4-Player Match") {
                            gameCenterManager.findMultiplayerMatch(playerCount: 4)
                        }
                        .disabled(true) // Disabled for now until full multiplayer implementation

                        Text("Multiplayer matches coming soon!")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    // Quick Actions Section
                    Section("Quick Actions") {
                        Button("View GameCenter Dashboard") {
                            presentGameCenterDashboard()
                        }

                        Button("View Achievements") {
                            presentGameCenterAchievements()
                        }
                    }
                }
            }
            .navigationTitle("GameCenter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .task {
            // Auto-authenticate on appear if not already authenticated
            if !gameCenterManager.isAuthenticated {
                await gameCenterManager.authenticate()
            }
        }
    }

    private func presentGameCenterDashboard() {
        let viewController = GKGameCenterViewController(state: .default)
        viewController.gameCenterDelegate = gameCenterDelegate

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(viewController, animated: true)
        }
    }

    private func presentGameCenterAchievements() {
        let viewController = GKGameCenterViewController(state: .achievements)
        viewController.gameCenterDelegate = gameCenterDelegate

        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first {
            window.rootViewController?.present(viewController, animated: true)
        }
    }
}

struct LeaderboardRowView: View {
    let entry: LeaderboardEntry
    let isCurrentPlayer: Bool

    var body: some View {
        HStack {
            // Rank
            Text("#\(entry.rank)")
                .font(.headline)
                .foregroundColor(rankColor)
                .frame(width: 40, alignment: .leading)

            // Player name
            Text(entry.playerName)
                .font(isCurrentPlayer ? .headline : .body)
                .fontWeight(isCurrentPlayer ? .bold : .regular)
                .foregroundColor(isCurrentPlayer ? .primary : .secondary)

            Spacer()

            // Score
            Text(entry.displayScore)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(scoreColor)
        }
        .padding(.vertical, 2)
        .background(isCurrentPlayer ? Color.accentColor.opacity(0.1) : Color.clear)
        .cornerRadius(6)
    }

    private var rankColor: Color {
        switch entry.rank {
        case 1: return .yellow
        case 2: return .gray
        case 3: return .orange
        default: return .secondary
        }
    }

    private var scoreColor: Color {
        if entry.score < 0 {
            return .green
        } else if entry.score == 0 {
            return .blue
        } else {
            return .red
        }
    }
}

// GameCenter delegate to handle view controller dismissal
class GameCenterDelegate: NSObject, GKGameCenterControllerDelegate {
    func gameCenterViewControllerDidFinish(_ gameCenterViewController: GKGameCenterViewController) {
        gameCenterViewController.dismiss(animated: true)
    }
}

#Preview {
    let mockManager = GameCenterManager(
        gameCenterService: MockGameCenterService(),
        persistenceService: MockPersistenceService(),
        eventBus: EventBus()
    )

    GameCenterView(gameCenterManager: mockManager)
}