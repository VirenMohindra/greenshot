//
//  NetworkClient.swift
//  GreenShot
//
//  Core network client for API communication and multiplayer support
//

import Foundation
import Combine
import Network

// MARK: - Network Client Protocol
protocol NetworkClientProtocol {
    var isConnected: Bool { get }
    var connectionPublisher: AnyPublisher<NetworkStatus, Never> { get }

    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T
    func upload<T: Decodable>(_ data: Data, to endpoint: APIEndpoint) async throws -> T
    func establishWebSocket(for endpoint: WebSocketEndpoint) async throws -> WebSocketConnection
}

// MARK: - Network Status
enum NetworkStatus: Equatable {
    case connected
    case disconnected
    case connecting
    case error(String)

    var isConnected: Bool {
        self == .connected
    }
}

// MARK: - API Endpoint
struct APIEndpoint {
    let path: String
    let method: HTTPMethod
    let headers: [String: String]
    let queryParameters: [String: String]
    let body: Data?
    let timeout: TimeInterval

    init(
        path: String,
        method: HTTPMethod = .GET,
        headers: [String: String] = [:],
        queryParameters: [String: String] = [:],
        body: Data? = nil,
        timeout: TimeInterval = 30.0
    ) {
        self.path = path
        self.method = method
        self.headers = headers
        self.queryParameters = queryParameters
        self.body = body
        self.timeout = timeout
    }
}

enum HTTPMethod: String {
    case GET = "GET"
    case POST = "POST"
    case PUT = "PUT"
    case DELETE = "DELETE"
    case PATCH = "PATCH"
}

// MARK: - WebSocket Types
struct WebSocketEndpoint {
    let path: String
    let protocols: [String]

    init(path: String, protocols: [String] = []) {
        self.path = path
        self.protocols = protocols
    }
}

protocol WebSocketConnection {
    var isConnected: Bool { get }
    var messagePublisher: AnyPublisher<Data, Never> { get }

    func send(_ data: Data) async throws
    func disconnect()
}

// MARK: - Network Errors
enum NetworkError: LocalizedError {
    case invalidURL
    case noConnection
    case requestFailed(Int, String)
    case decodingFailed(Error)
    case timeout
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noConnection:
            return "No network connection"
        case .requestFailed(let code, let message):
            return "Request failed (\(code)): \(message)"
        case .decodingFailed(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .timeout:
            return "Request timed out"
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}

// MARK: - Network Client Implementation
class NetworkClient: NetworkClientProtocol {
    private let baseURL: URL
    private let session: URLSession
    private let monitor: NWPathMonitor
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor")

    @Published private(set) var isConnected: Bool = false
    private let connectionSubject = CurrentValueSubject<NetworkStatus, Never>(.disconnected)

    var connectionPublisher: AnyPublisher<NetworkStatus, Never> {
        connectionSubject.eraseToAnyPublisher()
    }

    init(baseURL: URL, configuration: URLSessionConfiguration = .default) {
        self.baseURL = baseURL

        // Configure URL session
        configuration.timeoutIntervalForRequest = 30.0
        configuration.timeoutIntervalForResource = 60.0
        configuration.waitsForConnectivity = true
        self.session = URLSession(configuration: configuration)

        // Setup network monitoring
        self.monitor = NWPathMonitor()
        startNetworkMonitoring()
    }

    deinit {
        monitor.cancel()
    }

    // MARK: - Network Monitoring
    private func startNetworkMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionSubject.send(path.status == .satisfied ? .connected : .disconnected)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    // MARK: - HTTP Requests
    func request<T: Decodable>(_ endpoint: APIEndpoint) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }

        let request = try buildURLRequest(for: endpoint)

        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
                throw NetworkError.requestFailed(httpResponse.statusCode, errorMessage)
            }

            do {
                return try JSONDecoder().decode(T.self, from: data)
            } catch {
                throw NetworkError.decodingFailed(error)
            }

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    func upload<T: Decodable>(_ data: Data, to endpoint: APIEndpoint) async throws -> T {
        guard isConnected else {
            throw NetworkError.noConnection
        }

        var request = try buildURLRequest(for: endpoint)
        request.httpBody = data

        do {
            let (responseData, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.unknown(URLError(.badServerResponse))
            }

            guard 200..<300 ~= httpResponse.statusCode else {
                let errorMessage = String(data: responseData, encoding: .utf8) ?? "Unknown error"
                throw NetworkError.requestFailed(httpResponse.statusCode, errorMessage)
            }

            do {
                return try JSONDecoder().decode(T.self, from: responseData)
            } catch {
                throw NetworkError.decodingFailed(error)
            }

        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.unknown(error)
        }
    }

    // MARK: - WebSocket Connection
    func establishWebSocket(for endpoint: WebSocketEndpoint) async throws -> WebSocketConnection {
        guard isConnected else {
            throw NetworkError.noConnection
        }

        guard let url = URL(string: endpoint.path, relativeTo: baseURL) else {
            throw NetworkError.invalidURL
        }

        return try await WebSocketConnectionImpl(url: url, protocols: endpoint.protocols)
    }

    // MARK: - Helper Methods
    private func buildURLRequest(for endpoint: APIEndpoint) throws -> URLRequest {
        var components = URLComponents()
        components.scheme = baseURL.scheme
        components.host = baseURL.host
        components.port = baseURL.port
        components.path = baseURL.path + endpoint.path

        // Add query parameters
        if !endpoint.queryParameters.isEmpty {
            components.queryItems = endpoint.queryParameters.map { key, value in
                URLQueryItem(name: key, value: value)
            }
        }

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout

        // Set headers
        for (key, value) in endpoint.headers {
            request.setValue(value, forHTTPHeaderField: key)
        }

        // Set default headers
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Set body
        request.httpBody = endpoint.body

        return request
    }
}

// MARK: - WebSocket Implementation
class WebSocketConnectionImpl: NSObject, WebSocketConnection, URLSessionWebSocketDelegate {
    private let webSocketTask: URLSessionWebSocketTask
    private let session: URLSession

    @Published private(set) var isConnected: Bool = false
    private let messageSubject = PassthroughSubject<Data, Never>()

    var messagePublisher: AnyPublisher<Data, Never> {
        messageSubject.eraseToAnyPublisher()
    }

    init(url: URL, protocols: [String]) async throws {
        let configuration = URLSessionConfiguration.default
        self.session = URLSession(configuration: configuration)
        self.webSocketTask = session.webSocketTask(with: url, protocols: protocols)

        super.init()

        webSocketTask.delegate = self
        webSocketTask.resume()

        // Start receiving messages
        receiveMessage()

        // Wait for connection
        try await waitForConnection()
    }

    private func waitForConnection() async throws {
        // Simple timeout mechanism
        let timeout = 10.0
        let startTime = Date()

        while !isConnected && Date().timeIntervalSince(startTime) < timeout {
            try await Task.sleep(nanoseconds: 100_000_000) // 100ms
        }

        if !isConnected {
            throw NetworkError.timeout
        }
    }

    func send(_ data: Data) async throws {
        guard isConnected else {
            throw NetworkError.noConnection
        }

        let message = URLSessionWebSocketTask.Message.data(data)
        try await webSocketTask.send(message)
    }

    func disconnect() {
        isConnected = false
        webSocketTask.cancel(with: .normalClosure, reason: nil)
    }

    private func receiveMessage() {
        webSocketTask.receive { [weak self] result in
            switch result {
            case .success(let message):
                switch message {
                case .data(let data):
                    self?.messageSubject.send(data)
                case .string(let text):
                    if let data = text.data(using: .utf8) {
                        self?.messageSubject.send(data)
                    }
                @unknown default:
                    break
                }

                // Continue receiving
                self?.receiveMessage()

            case .failure(let error):
                print("WebSocket receive error: \(error)")
                self?.isConnected = false
            }
        }
    }

    // MARK: - URLSessionWebSocketDelegate
    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
        DispatchQueue.main.async {
            self.isConnected = true
        }
    }

    func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
        DispatchQueue.main.async {
            self.isConnected = false
        }
    }
}

// MARK: - API Endpoints for Golf Game
extension APIEndpoint {
    // MARK: - Authentication
    static func authenticate(credentials: [String: Any]) -> APIEndpoint {
        let body = try? JSONSerialization.data(withJSONObject: credentials)
        return APIEndpoint(
            path: "/auth/login",
            method: .POST,
            body: body
        )
    }

    static func refreshToken(token: String) -> APIEndpoint {
        return APIEndpoint(
            path: "/auth/refresh",
            method: .POST,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    // MARK: - Leaderboards
    static func getLeaderboard(category: String, timeframe: String = "all") -> APIEndpoint {
        return APIEndpoint(
            path: "/leaderboards/\(category)",
            queryParameters: ["timeframe": timeframe]
        )
    }

    static func submitScore(score: Int, category: String, token: String) -> APIEndpoint {
        let body = try? JSONSerialization.data(withJSONObject: [
            "score": score,
            "category": category,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ])

        return APIEndpoint(
            path: "/leaderboards/\(category)/scores",
            method: .POST,
            headers: ["Authorization": "Bearer \(token)"],
            body: body
        )
    }

    // MARK: - Multiplayer
    static func createMatch(settings: [String: Any], token: String) -> APIEndpoint {
        let body = try? JSONSerialization.data(withJSONObject: settings)
        return APIEndpoint(
            path: "/multiplayer/matches",
            method: .POST,
            headers: ["Authorization": "Bearer \(token)"],
            body: body
        )
    }

    static func joinMatch(matchId: String, token: String) -> APIEndpoint {
        return APIEndpoint(
            path: "/multiplayer/matches/\(matchId)/join",
            method: .POST,
            headers: ["Authorization": "Bearer \(token)"]
        )
    }

    static func getMatchState(matchId: String, token: String) -> APIEndpoint {
        return APIEndpoint(
            path: "/multiplayer/matches/\(matchId)",
            headers: ["Authorization": "Bearer \(token)"]
        )
    }
}

// MARK: - WebSocket Endpoints
extension WebSocketEndpoint {
    static func multiplayerMatch(matchId: String) -> WebSocketEndpoint {
        return WebSocketEndpoint(
            path: "/ws/matches/\(matchId)",
            protocols: ["golf-game-v1"]
        )
    }

    static func globalEvents() -> WebSocketEndpoint {
        return WebSocketEndpoint(
            path: "/ws/events",
            protocols: ["golf-game-v1"]
        )
    }
}