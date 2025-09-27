//
//  LeaderboardView.swift
//  GreenShot
//
//  Simple leaderboard view placeholder
//

import SwiftUI

struct LeaderboardView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Leaderboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                VStack(spacing: 12) {
                    LeaderboardRow(rank: 1, name: "Player 1", score: -5)
                    LeaderboardRow(rank: 2, name: "Player 2", score: -3)
                    LeaderboardRow(rank: 3, name: "Player 3", score: -1)
                    LeaderboardRow(rank: 4, name: "You", score: 2)
                    LeaderboardRow(rank: 5, name: "Player 5", score: 5)
                }
                .padding()

                Spacer()
            }
            .padding()
            .navigationTitle("Leaderboard")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct LeaderboardRow: View {
    let rank: Int
    let name: String
    let score: Int

    var body: some View {
        HStack {
            Text("\(rank)")
                .font(.headline)
                .frame(width: 30)

            Text(name)
                .font(.body)

            Spacer()

            Text(score > 0 ? "+\(score)" : "\(score)")
                .font(.headline)
                .foregroundColor(score <= 0 ? .green : .red)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(rank <= 3 ? Color.yellow.opacity(0.2) : Color.clear)
        .cornerRadius(8)
    }
}

#Preview {
    LeaderboardView()
}