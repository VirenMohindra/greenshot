//
//  CleanGameScene.swift
//  GreenShot
//
//  Lean SpriteKit scene that orchestrates all architectural layers
//

import SpriteKit
import SwiftUI
import ObjectiveC

class CleanGameScene: SKScene {
    // MARK: - Dependencies
    private let dependencies: DependencyContainer
    private weak var viewModel: GameViewModel?

    // MARK: - Scene Properties
    private let courseWorldSize = CGSize(width: 800, height: 1600)
    private var ballNode: SKNode?
    private var lastCameraUpdate: TimeInterval = 0

    // MARK: - State
    private var currentHole: Hole?
    private var isInitialized = false

    init(dependencies: DependencyContainer) {
        self.dependencies = dependencies
        super.init(size: UIScreen.main.bounds.size)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configureViewModel(_ viewModel: GameViewModel) {
        self.viewModel = viewModel
    }

    // MARK: - Scene Lifecycle
    override func didMove(to view: SKView) {
        guard !isInitialized else { return }

        setupScene()
        setupDelegates()
        setupPhysics()
        observeGameController()

        isInitialized = true
    }

    private func setupScene() {
        // Force set proper size if needed
        if size.width < 100 || size.height < 100 {
            size = UIScreen.main.bounds.size
        }

        // Set default background color
        backgroundColor = SKColor(red: 0.13, green: 0.37, blue: 0.15, alpha: 1.0) // Golf green

        // Setup camera
        let cameraNode = SKCameraNode()
        addChild(cameraNode)
        camera = cameraNode

        // Initialize camera controller
        dependencies.cameraController.delegate = self
    }

    private func setupDelegates() {
        dependencies.collisionHandler.delegate = self
        dependencies.touchInputHandler.delegate = self
        dependencies.cameraController.delegate = self
    }

    private func setupPhysics() {
        dependencies.physicsWorld.setupPhysics(in: self, worldSize: courseWorldSize)
        physicsWorld.contactDelegate = dependencies.collisionHandler
    }

    private func observeGameController() {
        // Listen for game state changes
        NotificationCenter.default.addObserver(
            forName: NotificationNames.gameStateChanged,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateForGameState()
        }

        // Listen for shot taken notifications
        NotificationCenter.default.addObserver(
            forName: NotificationNames.shotTaken,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let impulse = notification.userInfo?["impulse"] as? Velocity {
                self?.applyShotImpulse(impulse)
            }
        }
    }
}

// MARK: - Game State Management
extension CleanGameScene {
    private func updateForGameState() {
        let gameController = dependencies.gameController

        print("🔍 updateForGameState called")
        print("   Current course exists: \(gameController.currentCourse != nil)")
        print("   Current hole exists: \(gameController.currentCourse?.currentHole != nil)")
        print("   Golf ball exists: \(gameController.golfBall != nil)")

        // Update hole if needed
        if let newHole = gameController.currentCourse?.currentHole,
           newHole.id != currentHole?.id {
            print("🏌️ Setting up hole \(newHole.number)")
            setupHole(newHole)
            return // Don't update ball position after setup - setupHole already positioned it correctly
        }

        // Update ball position only if we're not setting up a new hole
        if let ball = gameController.golfBall {
            updateBallPosition(ball)
        }
    }

    private func setupHole(_ hole: Hole) {
        currentHole = hole

        print("🏌️ setupHole called for hole \(hole.number)")
        print("   Tee position: \(hole.teePosition)")
        print("   Pin position: \(hole.pinPosition)")

        // Render course
        dependencies.courseRenderer.renderCourse(hole: hole, in: self)
        dependencies.courseRenderer.renderObstacles(hole.obstacles, in: self)

        // Setup ball
        setupBall(at: hole.teePosition)

        // Setup hole pin
        setupHolePin(at: hole.pinPosition)

        // Configure collision handler
        dependencies.collisionHandler.configure(
            ball: dependencies.gameController.golfBall!,
            obstacles: hole.obstacles
        )

        // Focus camera on tee
        dependencies.cameraController.focusOn(position: hole.teePosition, immediate: true)
    }

    private func setupBall(at position: Position) {
        // Remove existing ball
        ballNode?.removeFromParent()

        // Create new ball
        ballNode = dependencies.ballRenderer.createBallNode()
        ballNode?.position = position.cgPoint

        // Add physics
        ballNode?.physicsBody = dependencies.physicsWorld.createBallPhysicsBody()

        // Ensure ball starts with zero velocity for proper control
        ballNode?.physicsBody?.velocity = CGVector.zero
        ballNode?.physicsBody?.angularVelocity = 0

        if let ball = ballNode {
            addChild(ball)
        }
    }

    private func setupHolePin(at position: Position) {
        // Remove existing hole elements
        childNode(withName: "pin")?.removeFromParent()
        childNode(withName: "holeVisual")?.removeFromParent()
        children.filter { $0.name == "holeRim" }.forEach { $0.removeFromParent() }

        // Create hole first (at actual hole position, not offset)
        let hole = SKShapeNode(circleOfRadius: 18) // Increased size for better visibility
        hole.fillColor = SKColor.black // Pure black for maximum contrast
        hole.strokeColor = SKColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 1.0) // Lighter stroke for definition
        hole.lineWidth = 3
        hole.position = CGPoint(x: position.x, y: position.y)
        hole.zPosition = 5 // Higher z-position to ensure visibility above green
        hole.name = "holeVisual"
        addChild(hole)

        print("🕳️ Created hole visual at position: \(hole.position) with z-position: \(hole.zPosition)")

        // Add hole rim for more realism
        let rim = SKShapeNode(circleOfRadius: 22) // Increased rim size
        rim.fillColor = .clear
        rim.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0) // More visible rim
        rim.lineWidth = 2
        rim.position = hole.position
        rim.zPosition = 5.1
        rim.name = "holeRim"
        addChild(rim)

        // Create pin container (offset for visual appeal)
        let pinContainer = SKNode()
        pinContainer.position = CGPoint(x: position.x + 8, y: position.y + 15)
        pinContainer.zPosition = 6
        pinContainer.name = "pin"

        // Create flagpole
        let pin = SKShapeNode(rect: CGRect(x: -1, y: 0, width: 2, height: 45))
        pin.fillColor = .white
        pin.strokeColor = .gray
        pinContainer.addChild(pin)

        // Create flag
        let flag = SKShapeNode(rect: CGRect(x: 0, y: 30, width: 20, height: 12))
        flag.fillColor = .red
        flag.strokeColor = SKColor(red: 0.8, green: 0.0, blue: 0.0, alpha: 1.0)
        flag.lineWidth = 1
        pinContainer.addChild(flag)

        // Add physics for hole detection (at actual hole position)
        let holePhysics = SKNode()
        holePhysics.position = CGPoint(x: position.x, y: position.y)
        holePhysics.physicsBody = dependencies.physicsWorld.createHolePhysicsBody()
        holePhysics.name = "holePhysics"
        addChild(holePhysics)

        // Add dampening area around hole for more realistic ball behavior
        let dampeningArea = SKNode()
        dampeningArea.position = CGPoint(x: position.x, y: position.y)
        dampeningArea.physicsBody = dependencies.physicsWorld.createHoleDampeningArea()
        dampeningArea.name = "holeDampening"
        addChild(dampeningArea)

        addChild(pinContainer)
    }

    private func updateBallPosition(_ ball: GolfBall) {
        dependencies.ballRenderer.updateBallPosition(ballNode!, position: ball.position)
        dependencies.ballRenderer.updateBallVisibility(ballNode!, isVisible: ball.isVisible)
    }

    private func applyShotImpulse(_ impulse: Velocity) {
        guard let ballNode = ballNode,
              let physicsBody = ballNode.physicsBody else { return }

        // Apply impulse to the physics body
        let impulseVector = CGVector(dx: impulse.dx, dy: impulse.dy)
        physicsBody.applyImpulse(impulseVector)
    }
}

// MARK: - Touch Handling
extension CleanGameScene {
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let ball = dependencies.gameController.golfBall else { return }

        dependencies.touchInputHandler.handleTouchesBegan(
            touches,
            in: self,
            ballPosition: ball.position,
            ballVelocity: ball.velocity,
            resetButtonPosition: nil
        )
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        dependencies.touchInputHandler.handleTouchesMoved(touches, in: self)
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dependencies.touchInputHandler.handleTouchesEnded(touches, in: self)
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dependencies.touchInputHandler.handleTouchesCancelled(touches, in: self)
    }
}

// MARK: - Zoom Handling
extension CleanGameScene {
    func handleZoom(scale: CGFloat) {
        dependencies.cameraController.updateZoom(scale)
        viewModel?.updateZoom(scale)
    }

    func finishZoom(scale: CGFloat) {
        handleZoom(scale: scale)
    }
}

// MARK: - Update Loop
extension CleanGameScene {
    private var ballTrailPositions: [Position] {
        get { objc_getAssociatedObject(self, &ballTrailKey) as? [Position] ?? [] }
        set { objc_setAssociatedObject(self, &ballTrailKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC) }
    }

    override func update(_ currentTime: TimeInterval) {
        guard let ball = dependencies.gameController.golfBall else { return }

        // Update ball physics state
        if let ballPhysics = ballNode?.physicsBody {
            let newVelocity = Velocity(ballPhysics.velocity)
            ball.updateVelocity(newVelocity)

            let newPosition = Position(ballNode!.position)
            ball.updatePosition(newPosition)

            // Track ball movement for trail when ball is moving
            if !newVelocity.isStationary {
                ballTrailPositions.append(newPosition)

                // Performance: Keep only last 15 positions (down from 30)
                if ballTrailPositions.count > 15 {
                    ballTrailPositions.removeFirst()
                }

                // Performance: Trail renderer now handles its own throttling
                dependencies.ballRenderer.createBallTrail(from: ballTrailPositions, in: self)
            } else if ballTrailPositions.count > 0 {
                // Clear trail when ball stops
                ballTrailPositions.removeAll()
                dependencies.ballRenderer.clearBallTrail(from: self)
            }
        }

        // Performance: Update camera following at 20fps (down from 60fps)
        let cameraUpdateInterval = 1.0 / 20.0 // 20fps instead of 10fps for smoother following
        if !ball.velocity.isStationary && currentTime - lastCameraUpdate > cameraUpdateInterval {
            dependencies.cameraController.followBall(
                ballPosition: ball.position,
                ballVelocity: ball.velocity
            )
            lastCameraUpdate = currentTime
        }

        // Check for hole completion
        dependencies.gameController.checkForHoleCompletion(
            ballPosition: ball.position,
            ballVelocity: ball.velocity
        )
    }
}

// Key for associated object storage
private var ballTrailKey: UInt8 = 0

// MARK: - Delegate Implementations
extension CleanGameScene: CollisionHandlerDelegate {
    func collisionHandler(_ handler: CollisionHandler, ballEnteredHole ball: GolfBall, at position: Position) {
        // Animate ball into hole
        dependencies.ballRenderer.animateBallIntoHole(ballNode!, holePosition: position) {
            // Ball animation complete
        }

        // Create celebration effect
        if let hole = currentHole {
            let score = Score(strokes: dependencies.gameController.currentStrokes, par: hole.par)
            let celebrationLevel = dependencies.scoringService.getCelebrationLevel(score)

            dependencies.effectsRenderer.createHoleInCelebration(
                at: position,
                celebrationLevel: celebrationLevel,
                in: self
            )

            dependencies.effectsRenderer.createScoreMessage(
                text: score.celebrationText,
                at: position,
                in: self
            )
        }
    }

    func collisionHandler(_ handler: CollisionHandler, ballHitObstacle ball: GolfBall, obstacle: Obstacle, effect: ObstacleEffect) {
        switch effect {
        case .penalty(let strokes, _):
            dependencies.effectsRenderer.createPenaltyMessage(
                text: "\(obstacle.type.displayName)! +\(strokes) Stroke",
                at: ball.position,
                in: self
            )

        default:
            break
        }
    }

    func collisionHandler(_ handler: CollisionHandler, ballWentOutOfBounds ball: GolfBall) {
        dependencies.effectsRenderer.createPenaltyMessage(
            text: "Out of Bounds! +1 Penalty Stroke",
            at: ball.position,
            in: self
        )
    }
}

extension CleanGameScene: TouchInputHandlerDelegate {
    func touchInputHandler(_ handler: TouchInputHandler, didStartDrag at: Position, ballPosition: Position) {
        // Show ball touch feedback
        if let ballNode = ballNode {
            dependencies.ballRenderer.showBallTouchFeedback(ballNode)
        }

        // Start trajectory preview - show initial preview point
        let initialTrajectory = dependencies.gameController.previewShot(
            dragStart: ballPosition,
            dragEnd: at,
            power: 1.0
        )

        // Clear any existing preview
        dependencies.ballRenderer.clearTrajectoryPreview(from: self)

        // Show initial preview
        if !initialTrajectory.isEmpty {
            let previewNodes = dependencies.ballRenderer.createTrajectoryPreview(initialTrajectory)
            previewNodes.forEach { addChild($0) }
        }
    }

    func touchInputHandler(_ handler: TouchInputHandler, didUpdateDrag to: Position, from start: Position) {
        // Show drag feedback
        if let ballNode = ballNode {
            dependencies.ballRenderer.showDragFeedback(ballNode, dragStart: start, dragEnd: to)
        }

        // Update trajectory preview
        let trajectory = dependencies.gameController.previewShot(
            dragStart: start,
            dragEnd: to,
            power: 1.0
        )

        // Clear previous preview
        dependencies.ballRenderer.clearTrajectoryPreview(from: self)

        // Show new preview
        let previewNodes = dependencies.ballRenderer.createTrajectoryPreview(trajectory)
        previewNodes.forEach { addChild($0) }
    }

    func touchInputHandler(_ handler: TouchInputHandler, didEndDrag at: Position, from start: Position, power: CGFloat) {
        // Execute shot
        dependencies.gameController.takeShot(
            dragStart: start,
            dragEnd: at,
            power: power
        )

        // Clear trajectory preview and touch feedback
        dependencies.ballRenderer.clearTrajectoryPreview(from: self)
        if let ballNode = ballNode {
            dependencies.ballRenderer.hideBallTouchFeedback(ballNode)
        }
    }

    func touchInputHandler(_ handler: TouchInputHandler, didCancelDrag: Void) {
        // Clear trajectory preview and touch feedback when canceling
        dependencies.ballRenderer.clearTrajectoryPreview(from: self)
        if let ballNode = ballNode {
            dependencies.ballRenderer.hideBallTouchFeedback(ballNode)
        }
        print("🚫 Shot canceled")
    }

    func touchInputHandler(_ handler: TouchInputHandler, didTapReset: Void) {
        dependencies.gameController.resetBallToTee()
    }

    func touchInputHandler(_ handler: TouchInputHandler, didStartPan at: Position) {
        // Pan started
    }

    func touchInputHandler(_ handler: TouchInputHandler, didUpdatePan to: Position, delta: Position) {
        dependencies.cameraController.panBy(delta: delta)
    }

    func touchInputHandler(_ handler: TouchInputHandler, didEndPan: Void) {
        // Pan ended
    }
}

extension CleanGameScene: CameraControllerDelegate {
    func cameraController(_ controller: CameraController, didUpdatePosition position: Position, duration: TimeInterval, animationType: CameraAnimationType) {
        guard let camera = camera else { return }

        if duration > 0 {
            let moveAction = SKAction.move(to: position.cgPoint, duration: duration)
            moveAction.timingMode = animationType.skTimingMode
            camera.run(moveAction)
        } else {
            camera.position = position.cgPoint
        }

        viewModel?.updateCameraPosition(position)
    }

    func cameraController(_ controller: CameraController, didUpdateZoom zoom: CGFloat) {
        camera?.setScale(1.0 / zoom)
        viewModel?.updateZoom(zoom)
    }
}

// MARK: - Extensions
extension CameraAnimationType {
    var skTimingMode: SKActionTimingMode {
        switch self {
        case .none: return .linear
        case .easeIn: return .easeIn
        case .easeOut: return .easeOut
        case .easeInOut: return .easeInEaseOut
        }
    }
}