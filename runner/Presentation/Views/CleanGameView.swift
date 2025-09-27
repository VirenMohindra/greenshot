//
//  CleanGameView.swift
//  runner
//
//  Refactored game view using clean architecture
//

import SwiftUI
import SpriteKit

struct CleanGameView: View {
    @StateObject private var viewModel: GameViewModel
    @State private var gameScene: CleanGameScene?

    // Shared dependency container
    private let container: DependencyContainer

    init() {
        // Create shared dependency injection container
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
            GameControlsView(viewModel: viewModel)
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
        .onAppear {
            if viewModel.gameState == .menu {
                viewModel.startNewGame()
            }
        }
    }
}

// MARK: - Dependency Injection Container
class DependencyContainer {
    // MARK: - Services
    lazy var physicsService: PhysicsServiceProtocol = PhysicsService()
    lazy var scoringService: ScoringServiceProtocol = ScoringService()
    lazy var holeGenerationService: HoleGenerationServiceProtocol = HoleGenerationService(scoringService: scoringService)

    // MARK: - Use Cases
    lazy var takeShotUseCase: TakeShotUseCaseProtocol = TakeShotUseCase(physicsService: physicsService)
    lazy var completeHoleUseCase: CompleteHoleUseCaseProtocol = CompleteHoleUseCase(scoringService: scoringService)
    lazy var navigateHolesUseCase: NavigateHolesUseCaseProtocol = NavigateHolesUseCase()
    lazy var updateCameraUseCase: UpdateCameraUseCaseProtocol = UpdateCameraUseCase()

    // MARK: - Controllers
    lazy var gameController: GameController = GameController(
        takeShotUseCase: takeShotUseCase,
        completeHoleUseCase: completeHoleUseCase,
        navigateHolesUseCase: navigateHolesUseCase,
        updateCameraUseCase: updateCameraUseCase,
        holeGenerationService: holeGenerationService
    )

    lazy var inputController: InputController = InputController()
    lazy var cameraController: CameraController = CameraController(
        initialPosition: Position(x: 400, y: 800), // Center of course
        courseSize: CGSize(width: 800, height: 1600),
        screenSize: UIScreen.main.bounds.size
    )

    // MARK: - Infrastructure
    lazy var physicsWorld: PhysicsWorldProtocol = PhysicsWorld()
    lazy var collisionHandler: CollisionHandler = CollisionHandler(physicsService: physicsService)
    lazy var touchInputHandler: TouchInputHandler = TouchInputHandler()

    // MARK: - Renderers
    lazy var courseRenderer: CourseRendererProtocol = CourseRenderer(courseWorldSize: CGSize(width: 800, height: 1600))
    lazy var ballRenderer: BallRendererProtocol = BallRenderer()
    lazy var uiRenderer: UIRendererProtocol = UIRenderer(scoringService: scoringService)
    lazy var effectsRenderer: EffectsRendererProtocol = EffectsRenderer()
}

#Preview {
    CleanGameView()
}
