//
//  AppCoordinatorView.swift
//  GreenShot
//
//  App navigation coordinator managing splash, menu, and game flow
//

import SwiftUI

enum AppScreen {
    case splash
    case mainMenu
    case game
}

struct AppCoordinatorView: View {
    @State private var currentScreen: AppScreen = .splash
    @State private var showSplash = true

    var body: some View {
        ZStack {
            switch currentScreen {
            case .splash:
                SplashScreenView {
                    withAnimation(.easeInOut(duration: 0.5)) {
                        currentScreen = .mainMenu
                    }
                }

            case .mainMenu:
                MainMenuView {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        currentScreen = .game
                    }
                }

            case .game:
                CleanGameView()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: currentScreen)
    }
}

#Preview {
    AppCoordinatorView()
}