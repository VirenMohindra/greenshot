//
//  CleanGameView.swift
//  GreenShot
//
//  Refactored game view using clean architecture
//

import SwiftUI
import SpriteKit

struct CleanGameView: View {
    @StateObject private var viewModel: GameViewModel
    @State private var gameScene: CleanGameScene?
    @State private var showCourseOverview = false

    // Shared dependency container (legacy bridge)
    private let container: DependencyContainer

    init() {
        // Configure services if not already configured
        let serviceContainer = ServiceContainer.shared
        if serviceContainer.resolve(PhysicsServiceProtocol.self) == nil {
            DefaultServiceConfiguration().configure(container: serviceContainer)
        }

        // Use legacy bridge for compatibility
        let container = DependencyContainer()
        let gameController = container.gameController
        let gameViewModel = GameViewModel(gameController: gameController)

        self.container = container
        self._viewModel = StateObject(wrappedValue: gameViewModel)
    }

    // Create the game scene
    var scene: SKScene {
        if gameScene == nil {
            // Use the SAME container instance
            let scene = CleanGameScene(dependencies: container)
            let screenSize = UIScreen.main.bounds.size
            scene.size = screenSize
            scene.scaleMode = .aspectFill
            scene.configureViewModel(viewModel)
            gameScene = scene
        }
        return gameScene ?? CleanGameScene(dependencies: container)
    }

    var body: some View {
        ZStack {
            // SpriteKit Scene with zoom gesture
            SpriteView(scene: scene)
                .ignoresSafeArea()
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            DispatchQueue.main.async {
                                gameScene?.handleZoom(scale: value)
                            }
                        }
                        .onEnded { value in
                            DispatchQueue.main.async {
                                gameScene?.finishZoom(scale: value)
                            }
                        }
                )

            // UI Overlay
            GameControlsView(viewModel: viewModel, showCourseOverview: $showCourseOverview)
        }
        .sheet(isPresented: $viewModel.showSettings) {
            SettingsView()
        }
        .sheet(isPresented: $viewModel.showLeaderboard) {
            LeaderboardView()
        }
        .sheet(isPresented: $viewModel.showHoleDebug) {
            if let course = viewModel.currentCourse {
                HoleDebugView(course: course)
            } else {
                Text("No course generated yet")
                    .padding()
            }
        }
        .sheet(isPresented: $showCourseOverview) {
            if let course = viewModel.currentCourse {
                CourseOverviewView(
                    holes: course.holes,
                    currentHoleIndex: viewModel.currentHoleIndex,
                    isPresented: $showCourseOverview
                )
            } else {
                Text("No course generated yet")
                    .padding()
            }
        }
        .onAppear {
            if viewModel.gameState == .menu {
                viewModel.startNewGame()
            }
        }
    }
}

#Preview {
    CleanGameView()
}
