//
//  EventBus.swift
//  GreenShot
//
//  Reactive event bus for type-safe communication between components
//  Provides Combine-based publishers for game events
//

import Foundation
import Combine

// MARK: - Event Bus Protocol
protocol EventBusProtocol {
    // MARK: - Publishing
    func publish<T: GameEvent>(_ event: T)

    // MARK: - Subscribing
    func publisher<T: GameEvent>(for eventType: T.Type) -> AnyPublisher<T, Never>
    func publisher(for notificationName: NSNotification.Name) -> AnyPublisher<[String: Any], Never>
}

// MARK: - Game Event Protocol
protocol GameEvent {
    var notificationName: NSNotification.Name { get }
    var userInfo: [String: Any] { get }
}

// MARK: - Event Bus Implementation
class EventBus: EventBusProtocol {
    static let shared = EventBus()

    private let notificationCenter: NotificationCenter
    private var cancellables = Set<AnyCancellable>()

    init(notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
    }

    // MARK: - Publishing
    func publish<T: GameEvent>(_ event: T) {
        notificationCenter.post(
            name: event.notificationName,
            object: nil,
            userInfo: event.userInfo
        )
    }

    // MARK: - Subscribing
    func publisher<T: GameEvent>(for eventType: T.Type) -> AnyPublisher<T, Never> {
        // This would need to be implemented with specific event mapping
        // For now, returning empty publisher
        return Empty<T, Never>().eraseToAnyPublisher()
    }

    func publisher(for notificationName: NSNotification.Name) -> AnyPublisher<[String: Any], Never> {
        notificationCenter.publisher(for: notificationName)
            .compactMap { notification in
                notification.userInfo as? [String: Any] ?? [:]
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Concrete Game Events

// MARK: - Game State Events
struct GameStateChangedEvent: GameEvent {
    let newState: GameState

    var notificationName: NSNotification.Name { NotificationNames.gameStateChanged }
    var userInfo: [String: Any] { ["newState": newState] }
}

struct GameStartedEvent: GameEvent {
    var notificationName: NSNotification.Name { NotificationNames.gameStarted }
    var userInfo: [String: Any] { [:] }
}

struct GameEndedEvent: GameEvent {
    let finalScore: Score

    var notificationName: NSNotification.Name { NotificationNames.gameEnded }
    var userInfo: [String: Any] { ["finalScore": finalScore] }
}

struct GamePausedEvent: GameEvent {
    var notificationName: NSNotification.Name { NotificationNames.gamePaused }
    var userInfo: [String: Any] { [:] }
}

struct GameResumedEvent: GameEvent {
    var notificationName: NSNotification.Name { NotificationNames.gameResumed }
    var userInfo: [String: Any] { [:] }
}

// MARK: - Hole Events
struct HoleStartedEvent: GameEvent {
    let hole: Hole

    var notificationName: NSNotification.Name { NotificationNames.holeStarted }
    var userInfo: [String: Any] { ["hole": hole] }
}

struct HoleCompletedEvent: GameEvent {
    let hole: Hole
    let score: Score

    var notificationName: NSNotification.Name { NotificationNames.holeCompleted }
    var userInfo: [String: Any] { ["hole": hole, "score": score] }
}

// MARK: - Shot Events
struct ShotTakenEvent: GameEvent {
    let power: Float
    let direction: Float
    let impulse: Velocity

    var notificationName: NSNotification.Name { NotificationNames.shotTaken }
    var userInfo: [String: Any] {
        ["power": power, "direction": direction, "impulse": impulse]
    }
}

struct ShotCompletedEvent: GameEvent {
    var notificationName: NSNotification.Name { NotificationNames.shotCompleted }
    var userInfo: [String: Any] { [:] }
}

struct BallStoppedEvent: GameEvent {
    let position: Position
    let velocity: Velocity

    var notificationName: NSNotification.Name { NotificationNames.ballStopped }
    var userInfo: [String: Any] { ["position": position, "velocity": velocity] }
}

// MARK: - Collision Events
struct BallEnteredHoleEvent: GameEvent {
    let position: Position

    var notificationName: NSNotification.Name { NotificationNames.ballEnteredHole }
    var userInfo: [String: Any] { ["position": position] }
}

struct BallHitObstacleEvent: GameEvent {
    let obstacle: Obstacle
    let effect: String // ObstacleEffect as string for now

    var notificationName: NSNotification.Name { NotificationNames.ballHitObstacle }
    var userInfo: [String: Any] { ["obstacle": obstacle, "effect": effect] }
}

struct BallWentOutOfBoundsEvent: GameEvent {
    let position: Position

    var notificationName: NSNotification.Name { NotificationNames.ballWentOutOfBounds }
    var userInfo: [String: Any] { ["position": position] }
}

// MARK: - Score Events
struct ScoreUpdatedEvent: GameEvent {
    let newScore: Score

    var notificationName: NSNotification.Name { NotificationNames.scoreUpdated }
    var userInfo: [String: Any] { ["newScore": newScore] }
}

struct AchievementUnlockedEvent: GameEvent {
    let achievement: Achievement

    var notificationName: NSNotification.Name { NotificationNames.achievementUnlocked }
    var userInfo: [String: Any] { ["achievement": achievement] }
}

// MARK: - Camera Events
struct CameraPositionChangedEvent: GameEvent {
    let newPosition: Position

    var notificationName: NSNotification.Name { NotificationNames.cameraPositionChanged }
    var userInfo: [String: Any] { ["newPosition": newPosition] }
}

struct ZoomLevelChangedEvent: GameEvent {
    let newZoom: CGFloat

    var notificationName: NSNotification.Name { NotificationNames.zoomLevelChanged }
    var userInfo: [String: Any] { ["newZoom": newZoom] }
}

// MARK: - Course Events
struct CourseGeneratedEvent: GameEvent {
    let course: Course

    var notificationName: NSNotification.Name { NotificationNames.courseGenerated }
    var userInfo: [String: Any] { ["course": course] }
}

struct CourseLoadedEvent: GameEvent {
    let course: Course

    var notificationName: NSNotification.Name { NotificationNames.courseLoaded }
    var userInfo: [String: Any] { ["course": course] }
}

// MARK: - Network Events (for future multiplayer)
struct NetworkConnectionChangedEvent: GameEvent {
    let isConnected: Bool

    var notificationName: NSNotification.Name { NotificationNames.networkConnectionChanged }
    var userInfo: [String: Any] { ["isConnected": isConnected] }
}

struct MultiplayerGameJoinedEvent: GameEvent {
    let matchId: String

    var notificationName: NSNotification.Name { NotificationNames.multiplayerGameJoined }
    var userInfo: [String: Any] { ["matchId": matchId] }
}

struct MultiplayerGameLeftEvent: GameEvent {
    let matchId: String

    var notificationName: NSNotification.Name { NotificationNames.multiplayerGameLeft }
    var userInfo: [String: Any] { ["matchId": matchId] }
}

// MARK: - Convenient EventBus Extensions
extension EventBus {
    // MARK: - Specific Event Publishers
    var gameStateChanged: AnyPublisher<GameState, Never> {
        publisher(for: NotificationNames.gameStateChanged)
            .compactMap { userInfo in
                userInfo["newState"] as? GameState
            }
            .eraseToAnyPublisher()
    }

    var shotTaken: AnyPublisher<(power: Float, direction: Float, impulse: Velocity), Never> {
        publisher(for: NotificationNames.shotTaken)
            .compactMap { userInfo in
                guard let power = userInfo["power"] as? Float,
                      let direction = userInfo["direction"] as? Float,
                      let impulse = userInfo["impulse"] as? Velocity else {
                    return nil
                }
                return (power: power, direction: direction, impulse: impulse)
            }
            .eraseToAnyPublisher()
    }

    var ballStopped: AnyPublisher<(position: Position, velocity: Velocity), Never> {
        publisher(for: NotificationNames.ballStopped)
            .compactMap { userInfo in
                guard let position = userInfo["position"] as? Position,
                      let velocity = userInfo["velocity"] as? Velocity else {
                    return nil
                }
                return (position: position, velocity: velocity)
            }
            .eraseToAnyPublisher()
    }

    var holeCompleted: AnyPublisher<(hole: Hole, score: Score), Never> {
        publisher(for: NotificationNames.holeCompleted)
            .compactMap { userInfo in
                guard let hole = userInfo["hole"] as? Hole,
                      let score = userInfo["score"] as? Score else {
                    return nil
                }
                return (hole: hole, score: score)
            }
            .eraseToAnyPublisher()
    }

    var achievementUnlocked: AnyPublisher<Achievement, Never> {
        publisher(for: NotificationNames.achievementUnlocked)
            .compactMap { userInfo in
                userInfo["achievement"] as? Achievement
            }
            .eraseToAnyPublisher()
    }
}

// MARK: - Reactive EventBus for SwiftUI Integration
class ReactiveEventBus: ObservableObject {
    private let eventBus: EventBusProtocol
    private var cancellables = Set<AnyCancellable>()

    // Published properties for UI reactivity
    @Published var currentGameState: GameState = .menu
    @Published var latestScore: Score?
    @Published var latestAchievement: Achievement?
    @Published var isGameActive: Bool = false

    init(eventBus: EventBusProtocol = EventBus.shared) {
        self.eventBus = eventBus
        setupSubscriptions()
    }

    convenience init() {
        self.init(eventBus: EventBus.shared)
    }

    private func setupSubscriptions() {
        // Subscribe to game state changes
        (eventBus as? EventBus)?.gameStateChanged
            .receive(on: DispatchQueue.main)
            .assign(to: \.currentGameState, on: self)
            .store(in: &cancellables)

        // Subscribe to achievement events
        (eventBus as? EventBus)?.achievementUnlocked
            .receive(on: DispatchQueue.main)
            .map { Optional($0) }
            .assign(to: \.latestAchievement, on: self)
            .store(in: &cancellables)

        // Track if game is active
        (eventBus as? EventBus)?.gameStateChanged
            .receive(on: DispatchQueue.main)
            .map { state in state == .playing }
            .assign(to: \.isGameActive, on: self)
            .store(in: &cancellables)
    }

    // Convenience methods for publishing events
    func publish<T: GameEvent>(_ event: T) {
        eventBus.publish(event)
    }
}